-- *************************************************
--		CREATE TABLES
-- *************************************************


--------------------------------------------------------------------------
-- DROP old tables
--------------------------------------------------------------------------

DROP TABLE Control;
DROP TABLE Alcohol_use;
DROP TABLE Session_attendance;
DROP TABLE Reminder;

DROP TABLE Specialist;
DROP TABLE Alcoholic;
DROP TABLE "Session";
DROP TABLE Session_places;
DROP TABLE Person;

DROP TABLE Address;

DROP SEQUENCE user_id_last;

--------------------------------------------------------------------------
-- CREATE tables
--------------------------------------------------------------------------

CREATE TABLE Address
(
    address_id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    town       VARCHAR(20)               NOT NULL,
    street     VARCHAR(20),
    house_n    INT                       NOT NULL,
    post_code  VARCHAR(5)                NOT NULL
);
CREATE UNIQUE INDEX address_town_street_post_code_ui
    ON Address (town, street, post_code);

CREATE TABLE Person
(
    person_id        INT         NOT NULL PRIMARY KEY,
    person_id_number VARCHAR(10) NOT NULL,
    first_name       VARCHAR(40) NOT NULL,
    last_name        VARCHAR(20) NOT NULL,
    tel_n            VARCHAR(12) NOT NULL
        CHECK (REGEXP_LIKE(TEL_N, '^[0-9]{12}$')),
    address_id       INT         NOT NULL,
    type             VARCHAR(12) NOT NULL
        CHECK (type IN ('Alcoholic', 'Specialist', 'Sponsor')),

    CONSTRAINT PERSON_ID_CHECK CHECK (
            REGEXP_LIKE(PERSON_ID_NUMBER, '^[0-9]{9,10}$')
            AND
            NOT REGEXP_LIKE(PERSON_ID_NUMBER, '^[0-9]{6}[0]{3}$')
        ),

    CONSTRAINT person_address_fk
        FOREIGN KEY (address_id) REFERENCES Address (address_id)
);
CREATE SEQUENCE user_id_last;
CREATE OR REPLACE TRIGGER generate_user_id
    BEFORE INSERT
    ON Person
    FOR EACH ROW
BEGIN
    :NEW.person_id := user_id_last.nextval;
END;


CREATE UNIQUE INDEX person_id_person_id_number_ui
    ON Person (person_id_number);



CREATE TABLE Specialist
(
    person_id         INT NOT NULL PRIMARY KEY,
    practise          VARCHAR(200),
    ambulance_address INT,

    CONSTRAINT specialist_ambulance_address_fk
        FOREIGN KEY (ambulance_address) REFERENCES Address (address_id),

    CONSTRAINT specialist_id_fk
        FOREIGN KEY (person_id) REFERENCES Person (person_id)
            ON DELETE CASCADE
);

CREATE TABLE Alcoholic
(
    person_id INT     NOT NULL PRIMARY KEY,
    gender    CHAR(1) NOT NULL
        CHECK ( gender IN ('M', 'F', 'U')),
    admission DATE,
    sponsor   INT,

    CONSTRAINT alcoholic_id_fk
        FOREIGN KEY (person_id) REFERENCES Person (person_id)
            ON DELETE CASCADE,

    CONSTRAINT alcoholics_sponsor_fk
        FOREIGN KEY (sponsor) REFERENCES Person (person_id)
            ON DELETE SET NULL

);

CREATE TABLE Session_places
(
    place_id      INT GENERATED AS IDENTITY PRIMARY KEY,
    place_name    VARCHAR(40) NOT NULL,
    place_address INT         NOT NULL,

    CONSTRAINT session_place_address_fk
        FOREIGN KEY (place_address) REFERENCES Address (address_id)
);

CREATE UNIQUE INDEX session_places_place_id_ui
    ON Session_places (place_name);


CREATE TABLE "Session"
(
    session_id      INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    session_date    TIMESTAMP                 NOT NULL,
    session_leader  INT,
    session_address INT,

    CONSTRAINT person_leading_session_fk
        FOREIGN KEY (session_leader) REFERENCES Person (person_id),

    CONSTRAINT session_address_fk
        FOREIGN KEY (session_address) REFERENCES Session_places (place_id)
);

CREATE UNIQUE INDEX session_date_leader_address_ui
    ON "Session" (session_date, session_leader, session_address);


CREATE TABLE Control
(
    control_id   INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    control_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    alcoholic    INT                       NOT NULL,
    specialist   INT                       NOT NULL,

    CONSTRAINT controled_alcoholic_fk
        FOREIGN KEY (alcoholic) REFERENCES Alcoholic (person_id)
            ON DELETE CASCADE,

    CONSTRAINT controled_by_specialist_fk
        FOREIGN KEY (specialist) REFERENCES Specialist (person_id)
            ON DELETE CASCADE
);

CREATE UNIQUE INDEX control_date_leader_address_ui
    ON Control (control_date, alcoholic, specialist);

CREATE TABLE Alcohol_use
(
    alcohol_use_id     INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    alcohol_type       VARCHAR(40),
    blood_alcohol_rate FLOAT(3),
    alcohol_percentage FLOAT(2),
    reason             VARCHAR(150),
    use_date           DATE,
    alcoholic          INT,

    CONSTRAINT alcoholic_used_fk
        FOREIGN KEY (alcoholic) REFERENCES Alcoholic (person_id)
            ON DELETE CASCADE

);

CREATE TABLE Reminder
(
    reminder_id   INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    reminder_date TIMESTAMP                 NOT NULL,
    alcoholic     INT                       NOT NULL,

    CONSTRAINT reminder_alcoholic_fk
        FOREIGN KEY (alcoholic) REFERENCES Alcoholic (person_id)
            ON DELETE CASCADE
);

CREATE UNIQUE INDEX reminder_date_alcoholic_ui
    ON Reminder (reminder_date, alcoholic);


CREATE TABLE Session_attendance
(
    attendee_id INT NOT NULL,
    session_key INT NOT NULL,

    CONSTRAINT attendance_pk
        PRIMARY KEY (attendee_id, session_key),

    CONSTRAINT session_attendance_attendee_fk
        FOREIGN KEY (attendee_id) REFERENCES Person (person_id)
            ON DELETE CASCADE,

    CONSTRAINT session_attendance_session_key_fk
        FOREIGN KEY (session_key) REFERENCES "Session" (session_id)
            ON DELETE CASCADE
);

COMMIT;

-- *************************************************
--		ADD DATA
-- *************************************************

---------------------------------------------------
-- TIME FORMATS
----------------------------------------------------

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS';


----------------------------------------------------
-- set all autogenerated ids to 1
---------------------------------------------------

-- ALTER TABLE Person
--     MODIFY (person_id GENERATED AS IDENTITY (START WITH 1));
ALTER TABLE Address
    MODIFY (address_id GENERATED AS IDENTITY (START WITH 1));
ALTER TABLE Session_places
    MODIFY (place_id GENERATED AS IDENTITY (START WITH 1));
ALTER TABLE "Session"
    MODIFY (session_id GENERATED AS IDENTITY (START WITH 1));
ALTER TABLE Control
    MODIFY (control_id GENERATED AS IDENTITY (START WITH 1));
ALTER TABLE Alcohol_use
    MODIFY (alcohol_use_id GENERATED AS IDENTITY (START WITH 1));
ALTER TABLE Reminder
    MODIFY (reminder_id GENERATED AS IDENTITY (START WITH 1));

---------------------------------------------------
-- ADDRESS
----------------------------------------------------

INSERT INTO ADDRESS(TOWN, STREET, HOUSE_N, POST_CODE)
VALUES ('Brno', 'Ceska', 20, '67175');
INSERT INTO ADDRESS(TOWN, STREET, HOUSE_N, POST_CODE)
VALUES ('Brno', 'Antoninska', 30, '67175');
INSERT INTO ADDRESS(TOWN, STREET, HOUSE_N, POST_CODE)
VALUES ('Brno', 'Antoninska', 80, '67172');
INSERT INTO ADDRESS(TOWN, STREET, HOUSE_N, POST_CODE)
VALUES ('Brno', 'Lidicka', 22, '67172');

INSERT INTO ADDRESS(TOWN, STREET, HOUSE_N, POST_CODE)
VALUES ('Brno', 'Huskova', 1123, '67170');

INSERT INTO ADDRESS(TOWN, STREET, HOUSE_N, POST_CODE)
VALUES ('Brno', 'Purkynova', 93, '67170');


-----------------------------------------------------
-- PERSON
----------------------------------------------------

INSERT INTO PERSON(PERSON_ID_NUMBER, FIRST_NAME, LAST_NAME, TEL_N, ADDRESS_ID, TYPE)
VALUES ('829189768', 'Ruth', 'Fox', '420111222333', 1, 'Alcoholic');

INSERT INTO PERSON(PERSON_ID_NUMBER, FIRST_NAME, LAST_NAME, TEL_N, ADDRESS_ID, TYPE)
VALUES ('774239829', 'Isabelle', 'Squirrel', '420999888777', 2, 'Specialist');

INSERT INTO PERSON(PERSON_ID_NUMBER, FIRST_NAME, LAST_NAME, TEL_N, ADDRESS_ID, TYPE)
VALUES ('978169951', 'Justin', 'Frog', '420666555444', 3, 'Sponsor');

INSERT INTO PERSON(PERSON_ID_NUMBER, FIRST_NAME, LAST_NAME, TEL_N, ADDRESS_ID, TYPE)
VALUES ('937279992', 'Lisa', 'Owl', '420111222555', 4, 'Alcoholic');

INSERT INTO PERSON(PERSON_ID_NUMBER, FIRST_NAME, LAST_NAME, TEL_N, ADDRESS_ID, TYPE)
VALUES ('951139706', 'Jason', 'Fawn', '420111222444', 5, 'Alcoholic');

INSERT INTO PERSON(PERSON_ID_NUMBER, FIRST_NAME, LAST_NAME, TEL_N, ADDRESS_ID, TYPE)
VALUES ('837135541', 'Tom', 'Newbie', '420344574234', 4, 'Alcoholic');


-----------------------------------------------------
-- ALCOHOLIC, SPECIALIST
----------------------------------------------------

INSERT INTO ALCOHOLIC(PERSON_ID, GENDER, ADMISSION, SPONSOR)
VALUES (1, 'F', '05/01/2020', 3);

INSERT INTO ALCOHOLIC(PERSON_ID, GENDER, ADMISSION, SPONSOR)
VALUES (4, 'F', '23/03/2019', 3);

INSERT INTO ALCOHOLIC(PERSON_ID, GENDER, ADMISSION, SPONSOR)
VALUES (5, 'M', '26/03/2019', 4);

INSERT INTO ALCOHOLIC(PERSON_ID, GENDER, ADMISSION)
VALUES (6, 'M', '08/04/2019');

INSERT INTO SPECIALIST(PERSON_ID, PRACTISE, AMBULANCE_ADDRESS)
VALUES (2, 'Psychiatria Brno', 5);

-----------------------------------------------------
-- SESSION tables
----------------------------------------------------

INSERT INTO SESSION_PLACES(PLACE_NAME, PLACE_ADDRESS)
VALUES ('Purkynovy koleje', 6);

INSERT INTO SESSION_PLACES(PLACE_NAME, PLACE_ADDRESS)
VALUES ('Psychiatrie', 5);

INSERT INTO SESSION_PLACES(PLACE_NAME, PLACE_ADDRESS)
VALUES ('Psychiatrie, Seminarka', 5);

INSERT INTO "Session"(SESSION_DATE, SESSION_LEADER, SESSION_ADDRESS)
VALUES ('06/01/2020 19:00:00', 2, 1);

INSERT INTO "Session"(SESSION_DATE, SESSION_LEADER, SESSION_ADDRESS)
VALUES ('06/03/2020 15:00:00', 2, 1);

INSERT INTO "Session"(SESSION_DATE, SESSION_LEADER, SESSION_ADDRESS)
VALUES ('06/04/2020 18:00:00', 2, 2);


INSERT INTO SESSION_ATTENDANCE(ATTENDEE_ID, SESSION_KEY)
VALUES (1, 1);
INSERT INTO SESSION_ATTENDANCE(ATTENDEE_ID, SESSION_KEY)
VALUES (2, 1);
INSERT INTO SESSION_ATTENDANCE(ATTENDEE_ID, SESSION_KEY)
VALUES (3, 1);
INSERT INTO SESSION_ATTENDANCE(ATTENDEE_ID, SESSION_KEY)
VALUES (4, 1);
INSERT INTO SESSION_ATTENDANCE(ATTENDEE_ID, SESSION_KEY)
VALUES (5, 1);

INSERT INTO SESSION_ATTENDANCE(ATTENDEE_ID, SESSION_KEY)
VALUES (1, 2);
INSERT INTO SESSION_ATTENDANCE(ATTENDEE_ID, SESSION_KEY)
VALUES (2, 2);
INSERT INTO SESSION_ATTENDANCE(ATTENDEE_ID, SESSION_KEY)
VALUES (4, 2);


---------------------------------------------------
-- CONTROL
----------------------------------------------------

INSERT INTO CONTROL(control_date, alcoholic, specialist)
VALUES ('23/03/2020 18:00:00', 1, 2);

INSERT INTO CONTROL(control_date, alcoholic, specialist)
VALUES ('27/03/2020 10:00:00', 5, 2);

----------------------------------------------------
-- ALCOHOL USE
----------------------------------------------------

INSERT INTO ALCOHOL_USE(ALCOHOL_TYPE, BLOOD_ALCOHOL_RATE, ALCOHOL_PERCENTAGE, REASON, USE_DATE, ALCOHOLIC)
VALUES ('Wine', 1.2, 12, 'Death of a son', '24/03/2020', 1);


COMMIT;


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

COMMIT;

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

COMMIT;

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

        SELECT COUNT(*)
        INTO p_alcoholics
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

COMMIT;

-- valid session id
BEGIN
    count_alcoholics_at_session(1);
END;

-- invalid session id
BEGIN
    count_alcoholics_at_session(100);
END;


SELECT *
from SESSION_ATTENDANCE;

ROLLBACK;

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

COMMIT;

SELECT *
FROM REMINDER;

BEGIN
    add_reminder(1);
END;

ROLLBACK;

---------------------------------------------------
-- EXPLAIN PLAN AND INDEX
---------------------------------------------------

-- Which alcoholics used alcohol and how many times have they drank?
EXPLAIN PLAN FOR
SELECT P.PERSON_ID              as id,
       P.FIRST_NAME             as name,
       P.LAST_NAME              as last_name,
       COUNT(AU.ALCOHOL_USE_ID) as count
FROM PERSON P
         JOIN ALCOHOL_USE AU ON P.PERSON_ID = AU.ALCOHOLIC
GROUP BY P.LAST_NAME, P.FIRST_NAME, P.PERSON_ID
HAVING COUNT(AU.ALCOHOL_USE_ID) > 0
ORDER BY count;
SELECT *
FROM TABLE (DBMS_XPLAN.DISPLAY);

CREATE INDEX alcohol_use_i ON ALCOHOL_USE (ALCOHOLIC);

EXPLAIN PLAN FOR
SELECT P.PERSON_ID              as id,
       P.FIRST_NAME             as name,
       P.LAST_NAME              as last_name,
       COUNT(AU.ALCOHOL_USE_ID) as count
FROM PERSON P
         JOIN ALCOHOL_USE AU ON P.PERSON_ID = AU.ALCOHOLIC
GROUP BY P.LAST_NAME, P.FIRST_NAME, P.PERSON_ID
HAVING COUNT(AU.ALCOHOL_USE_ID) > 0
ORDER BY count;
SELECT *
FROM TABLE (DBMS_XPLAN.DISPLAY);

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
DROP MATERIALIZED VIEW alcoholic_control_count;

CREATE MATERIALIZED VIEW alcoholic_control_count BUILD IMMEDIATE AS
SELECT P.PERSON_ID,
       P.LAST_NAME,
       P.FIRST_NAME,
       COUNT(CONTROL.ALCOHOLIC) AS CONTROL_COUNT
FROM PERSON P
         JOIN ALCOHOLIC A ON P.PERSON_ID = A.PERSON_ID
         LEFT JOIN CONTROL ON CONTROL.ALCOHOLIC = P.PERSON_ID
GROUP BY P.PERSON_ID, P.LAST_NAME, P.FIRST_NAME
ORDER BY CONTROL_COUNT;

SELECT *
FROM alcoholic_control_count;

UPDATE PERSON
SET LAST_NAME = 'Smith'
WHERE PERSON_ID = 1;

-- it wont be changed here
SELECT *
FROM alcoholic_control_count;

-- update
BEGIN
    DBMS_MVIEW.REFRESH('alcoholic_control_count');
END;

-- updated
SELECT *
FROM alcoholic_control_count;
