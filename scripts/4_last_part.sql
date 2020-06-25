-- *************************************************
--		FOURTH PART
-- *************************************************

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS';


---------------------------------------------------
-- Triggers (3/2)
----------------------------------------------------

-- 1 --
-- Check person ID number

CREATE OR REPLACE TRIGGER check_person_id_number
    BEFORE INSERT OR UPDATE OF PERSON_ID_NUMBER
    ON PERSON
    FOR EACH ROW
DECLARE
    v_id_num PERSON.PERSON_ID_NUMBER%TYPE;
    v_year   number;
    v_month  number;
    v_day    number;
    v_end    number;

    person_id_exception EXCEPTION;

BEGIN
    v_id_num := :NEW.PERSON_ID_NUMBER;

    v_year := TO_NUMBER(SUBSTR(v_id_num, 0, 2));
    v_month := TO_NUMBER(SUBSTR(v_id_num, 2, 2));
    v_day := TO_NUMBER(SUBSTR(v_id_num, 4, 2));

    -- length of person id
    IF (LENGTH(v_id_num) = 10) THEN
        v_end := TO_NUMBER(SUBSTR(v_id_num, 6, 4));
    ELSIF (LENGTH(v_id_num) = 9) THEN
        v_end := TO_NUMBER(SUBSTR(v_id_num, 6, 3));
        IF (v_end = 0) THEN
            RAISE person_id_exception;
        END IF;
    ELSE
        RAISE person_id_exception;
    END IF;

    -- month
    IF (v_month > 50) THEN
        v_month := v_month - 50;
    END IF;

    IF (v_month < 1 OR v_month > 12) THEN
        RAISE person_id_exception;
    END IF;

    -- day
    IF (v_day < 1 OR v_day > 31) THEN
        RAISE person_id_exception;
    END IF;

    -- modulo 11
    v_id_num := TO_NUMBER(v_id_num);
    IF (MOD(v_id_num, 11) != 0) THEN
        RAISE person_id_exception;
    end if;

EXCEPTION
    WHEN VALUE_ERROR OR person_id_exception THEN
        Raise_Application_Error(-20001, 'Invalid person id number');
    WHEN OTHERS THEN
        Raise_Application_Error(-20000, 'Unknown ERROR');

END;
/

-- valid
INSERT INTO PERSON(PERSON_ID_NUMBER, FIRST_NAME, LAST_NAME, TEL_N, ADDRESS_ID, TYPE)
VALUES ('702261175', 'Ruth', 'Fox', '420111222333', 1, 'Alcoholic');

-- not valid
-- mod 11
INSERT INTO PERSON(PERSON_ID_NUMBER, FIRST_NAME, LAST_NAME, TEL_N, ADDRESS_ID, TYPE)
VALUES ('5555555555', 'Ruth', 'Fox', '420111222333', 1, 'Alcoholic');

ROLLBACK;

-- 2 --
-- Check if session place is not already reserved

CREATE OR REPLACE TRIGGER check_session_collision
    BEFORE INSERT OR UPDATE OF SESSION_DATE
    ON "Session"
    FOR EACH ROW
DECLARE
    v_coll_num number;
BEGIN

    SELECT COUNT(*)
    INTO v_coll_num
    FROM "Session"
    WHERE SESSION_ADDRESS = :NEW.SESSION_ADDRESS
      AND :NEW.SESSION_DATE >= SESSION_DATE
      AND :NEW.SESSION_DATE < SESSION_DATE + interval '60' minute;

    IF (v_coll_num != 0) THEN
        Raise_Application_Error(-20002, 'Can not add new Session. Date collision');
    END IF;
END;

SELECT *
FROM "Session";

-- valid
INSERT INTO "Session"(SESSION_DATE, SESSION_LEADER, SESSION_ADDRESS)
VALUES ('06/04/2021 18:00:01', 2, 2);

-- not valid
INSERT INTO "Session"(SESSION_DATE, SESSION_LEADER, SESSION_ADDRESS)
VALUES ('06/04/2020 18:00:01', 2, 2);

ROLLBACK;

-- 3 --
-- Generating PK
-- Located in section 1, table Person

---------------------------------------------------
-- Procedures (1/2)
----------------------------------------------------

-- 1 --
-- Count alcoholics at session (max 12)
CREATE OR REPLACE PROCEDURE count_alcoholics_at_session(p_session_name number)
AS
    p_alcoholics        number;
    p_session_id        "Session".SESSION_ID%TYPE;
    p_target_session_id "Session".SESSION_ID%TYPE;
    CURSOR cursor_sessions IS SELECT SESSION_KEY
                              FROM SESSION_ATTENDANCE;
BEGIN

    p_alcoholics := 0;

    SELECT SESSION_ID
    INTO p_target_session_id
    FROM "Session"
    WHERE SESSION_ID = p_session_name;

    OPEN cursor_sessions;

    LOOP
        FETCH cursor_sessions INTO p_session_id;
        EXIT WHEN cursor_sessions%NOTFOUND;

        SELECT COUNT(*) INTO p_alcoholics
        FROM SESSION_ATTENDANCE SA
        JOIN "Session" S on SA.session_key = S.session_id
        JOIN ALCOHOLIC A on SA.attendee_id = A.PERSON_ID
        WHERE SA.session_key = p_target_session_id
        GROUP BY SA.session_key
        ORDER BY SA.session_key;

        EXIT WHEN cursor_sessions%FOUND;
    END LOOP;
    CLOSE cursor_sessions;


    DBMS_OUTPUT.PUT_LINE('Session ID ' || p_session_name || ' has attended ' ||
                         p_alcoholics || ' alcoholics.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        BEGIN
            DBMS_OUTPUT.PUT_LINE('Session has not been found');
        END;
END;

-- valid session id
BEGIN
    count_alcoholics_at_session(1);
END;

-- invalid session id
BEGIN
    count_alcoholics_at_session(100);
END;

SELECT * from SESSION_ATTENDANCE;

-- 2 --
-- Add remainder to alcoholics, who did not attend session in N months
CREATE OR REPLACE PROCEDURE add_reminder(p_months_num number) AS
    p_alcoholic         ALCOHOLIC.PERSON_ID%TYPE;
    p_last_session_date "Session".SESSION_DATE%TYPE;
    p_current_ts        TIMESTAMP;
    p_months_str        VARCHAR(5);
    CURSOR p_cursor_alcoholic IS SELECT PERSON_ID
                                 FROM ALCOHOLIC;
BEGIN
    OPEN p_cursor_alcoholic;
    p_current_ts := CURRENT_TIMESTAMP;
    p_months_str := TO_CHAR(p_months_num);

    LOOP
        FETCH p_cursor_alcoholic into p_alcoholic;
        EXIT WHEN p_cursor_alcoholic%NOTFOUND;

        BEGIN

            SELECT SESSION_DATE
            INTO p_last_session_date
            FROM SESSION_ATTENDANCE SA
                     INNER JOIN "Session" S ON SA.SESSION_KEY = S.SESSION_ID
            WHERE SA.ATTENDEE_ID = p_alcoholic
            ORDER BY S.SESSION_DATE
            FETCH FIRST ROW ONLY;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                BEGIN
                    p_last_session_date := p_current_ts;
                END;
        END;

        IF (p_current_ts > p_last_session_date + NUMTOYMINTERVAL(p_months_num, 'MONTH')) THEN
            INSERT INTO REMINDER(REMINDER_DATE, ALCOHOLIC)
            VALUES (p_current_ts, p_alcoholic);
        END IF;

    END LOOP;
    CLOSE p_cursor_alcoholic;
END;

SELECT *
FROM REMINDER;

BEGIN
    add_reminder(1);
END;

---------------------------------------------------
-- EXPLAIN PLAN AND INDEX
---------------------------------------------------
-- Which alcoholics used alcohol and how many times have they drank?
EXPLAIN PLAN FOR
SELECT
    P.PERSON_ID as id,
    P.FIRST_NAME as name,
    P.LAST_NAME  as last_name,
    COUNT(AU.ALCOHOL_USE_ID) as count
FROM PERSON P
JOIN ALCOHOL_USE AU ON P.PERSON_ID = AU.ALCOHOLIC
GROUP BY P.LAST_NAME, P.FIRST_NAME, P.PERSON_ID
HAVING COUNT(AU.ALCOHOL_USE_ID) > 0
ORDER BY count;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

CREATE INDEX alcohol_use_i ON ALCOHOL_USE(ALCOHOLIC);

EXPLAIN PLAN FOR
SELECT
    P.PERSON_ID as id,
    P.FIRST_NAME as name,
    P.LAST_NAME  as last_name,
    COUNT(AU.ALCOHOL_USE_ID) as count
FROM PERSON P
JOIN ALCOHOL_USE AU ON P.PERSON_ID = AU.ALCOHOLIC
GROUP BY P.LAST_NAME, P.FIRST_NAME, P.PERSON_ID
HAVING COUNT(AU.ALCOHOL_USE_ID) > 0
ORDER BY count;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

DROP INDEX alcohol_use_i;
ROLLBACK;
--------------------------------------------------
-- PRIVILEGES
--------------------------------------------------
GRANT ALL ON ADDRESS TO xmusko00;
GRANT ALL ON PERSON TO xmusko00;
GRANT ALL ON SPECIALIST TO xmusko00;
GRANT ALL ON ALCOHOLIC TO xmusko00;
GRANT ALL ON "Session" TO xmusko00;
GRANT ALL ON SESSION_PLACES TO xmusko00;
GRANT ALL ON CONTROL TO xmusko00;
GRANT ALL ON ALCOHOL_USE TO xmusko00;
GRANT ALL ON SESSION_ATTENDANCE TO xmusko00;
GRANT ALL ON REMINDER TO xmusko00;

GRANT EXECUTE ON count_alcoholics_at_session TO xmusko00;
GRANT EXECUTE ON add_reminder TO xmusko00;


---------------------------------------------------
-- MATERIALIZED VIEW
---------------------------------------------------
-- Materialized view at all alcoholics and number of their controls

CREATE MATERIALIZED VIEW alcoholic_control_count AS
SELECT
    P.PERSON_ID,
    P.LAST_NAME,
    P.FIRST_NAME,
    COUNT(C.ALCOHOLIC) AS CONTROL_COUNT
FROM PERSON P
JOIN ALCOHOLIC A ON P.PERSON_ID = A.PERSON_ID
LEFT JOIN CONTROL C ON C.ALCOHOLIC = P.PERSON_ID
GROUP BY P.PERSON_ID, P.LAST_NAME, P.FIRST_NAME
ORDER BY CONTROL_COUNT;

SELECT * FROM alcoholic_control_count;

UPDATE PERSON SET LAST_NAME = 'Smith' WHERE PERSON_ID = 1;

-- it wont be changed here
SELECT  * FROM alcoholic_control_count;

