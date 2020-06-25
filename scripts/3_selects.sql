
---------------------------------------------------
-- 2 Tables Join (3/2)
---------------------------------------------------

-- 1 --
-- Which alcoholics are without a sponsor?
-- (id, name, last name)
SELECT P.PERSON_ID  AS ID,
       P.FIRST_NAME AS FIRST_NAME,
       P.LAST_NAME  AS LAST_NAME
FROM PERSON P
         JOIN ALCOHOLIC A ON A.PERSON_ID = P.PERSON_ID
WHERE A.SPONSOR is null;

-- 2 --
-- Which alcoholics live together?
-- (id, name, last name, id, name, last name)
SELECT P1.PERSON_ID  AS ID,
       P1.FIRST_NAME AS FIRST_NAME,
       P1.LAST_NAME  AS LAST_NAME,
       P2.PERSON_ID  AS ID,
       P2.FIRST_NAME AS FIRST_NAME,
       P2.LAST_NAME  AS LAST_NAME
FROM PERSON P1
         CROSS JOIN PERSON P2
where P1.PERSON_ID < P2.PERSON_ID
  and P1.ADDRESS_ID = P2.ADDRESS_ID
  and P1.TYPE = 'Alcoholic'
  and P2.TYPE = 'Alcoholic'
ORDER BY P1.PERSON_ID;

-- 3 --
-- Which alcoholics are women?
-- (id, name, last name)
SELECT P.PERSON_ID  AS ID,
       P.FIRST_NAME AS FIRST_NAME,
       P.LAST_NAME  AS LAST_NAME
FROM PERSON P
         JOIN ALCOHOLIC A ON A.PERSON_ID = P.PERSON_ID
WHERE A.GENDER = 'F'
ORDER BY LAST_NAME, FIRST_NAME;

---------------------------------------------------
-- 3 Tables Join (1/1)
---------------------------------------------------

-- 1 --
-- Which alcoholics used alcohol?
-- (id, name, last name)
SELECT P.PERSON_ID  AS ID,
       P.FIRST_NAME AS FIRST_NAME,
       P.LAST_NAME  AS LAST_NAME
FROM PERSON P
         JOIN ALCOHOLIC A ON A.PERSON_ID = P.PERSON_ID
         JOIN ALCOHOL_USE AU ON AU.ALCOHOLIC = A.PERSON_ID
ORDER BY LAST_NAME, FIRST_NAME;

---------------------------------------------------
-- Group by with Aggregate functions (3/1)
---------------------------------------------------

-- 1 --
-- How many controls had alcoholic?
-- (name, last name, number of controls)
SELECT P.PERSON_ID         AS ID,
       P.FIRST_NAME        AS FIRST_NAME,
       P.LAST_NAME         AS LAST_NAME,
       COUNT(C.CONTROL_ID) AS COUNT
FROM PERSON P
         JOIN CONTROL C ON C.ALCOHOLIC = P.PERSON_ID
GROUP BY P.PERSON_ID, P.FIRST_NAME, P.LAST_NAME
HAVING COUNT(C.CONTROL_ID) > 0
ORDER BY P.LAST_NAME, P.FIRST_NAME;

-- 2 --
-- How many alcoholics have attended a session?
-- (session id, session date, number of alcoholics attending)
SELECT S.SESSION_ID          as ID,
       S.SESSION_DATE        as SESSION_DATE,
       COUNT(SA.SESSION_KEY) as COUNNT
FROM "Session" S
         JOIN SESSION_ATTENDANCE SA ON SA.SESSION_KEY = S.SESSION_ID
GROUP BY S.SESSION_ID, SESSION_DATE
ORDER BY S.SESSION_ID;

-- 3 --
-- Number of admitted alcoholics each month
-- (month, year, number of admitted alcoholics)
SELECT
    EXTRACT( month  from A.ADMISSION) as MONTH,
    EXTRACT( year from A.ADMISSION) as YEAR,
    COUNT(*) as NEW_ALCOHOLICS

FROM ALCOHOLIC A
LEFT JOIN ALCOHOL_USE AU on A.PERSON_ID = AU.ALCOHOLIC
GROUP BY EXTRACT( month  from A.ADMISSION),  EXTRACT( year from A.ADMISSION);

---------------------------------------------------
-- Exists (1/1)
---------------------------------------------------

-- 1 --
-- Which alcoholics have attended at least one session in the past 3 months?
-- (id, name, last name)
SELECT DISTINCT P.PERSON_ID  AS ID,
                P.FIRST_NAME AS FIRST_NAME,
                P.LAST_NAME  AS LAST_NAME
FROM PERSON P
         JOIN ALCOHOLIC A ON P.PERSON_ID = A.PERSON_ID
         JOIN SESSION_ATTENDANCE SA on A.PERSON_ID = SA.ATTENDEE_ID
         JOIN "Session" S on SA.SESSION_KEY = S.SESSION_ID
WHERE EXISTS(
              SELECT SA.ATTENDEE_ID
              FROM SESSION_ATTENDANCE SA
              WHERE SA.SESSION_KEY = S.SESSION_ID
                AND SESSION_DATE > add_months(SYSDATE, -3)
          )
ORDER BY LAST_NAME, FIRST_NAME;

---------------------------------------------------
-- In (2/1)
---------------------------------------------------

-- 1 --
-- Which session places hasn't been used?
-- (id, name of the place)
SELECT SP.PLACE_ID,
       SP.PLACE_NAME
FROM SESSION_PLACES SP
WHERE SP.PLACE_ID NOT IN (
    SELECT S.SESSION_ADDRESS
    FROM "Session" S
);

-- 2 --
-- Who is sponsoring an alcoholic who used alcohol?
-- (id, name, last name)
SELECT
    P.PERSON_ID,
    P.FIRST_NAME,
    P.LAST_NAME
FROM PERSON P
WHERE P.PERSON_ID IN (
    SELECT A.SPONSOR
    FROM ALCOHOLIC A
    RIGHT JOIN ALCOHOL_USE AU on A.PERSON_ID = AU.ALCOHOLIC);


---------------------------------------------------
-- Views
---------------------------------------------------

CREATE OR REPLACE VIEW ALCOHOLIC_V AS
SELECT P.PERSON_ID,
       P.PERSON_ID_NUMBER,
       P.FIRST_NAME,
       P.LAST_NAME,
       P.TEL_N,
       AD.ADDRESS_ID, TOWN, STREET, HOUSE_N, POST_CODE,
       A.GENDER,
       A.ADMISSION,
       A.SPONSOR     as SPONSOR_ID,
       SP.FIRST_NAME as SPONSOR_FIRST_NAME,
       SP.LAST_NAME  as SPONSOR_LAST_NAME

FROM PERSON P
         JOIN ALCOHOLIC A ON P.PERSON_ID = A.PERSON_ID
         JOIN PERSON SP ON SP.PERSON_ID = SPONSOR
         LEFT JOIN ADDRESS AD on P.ADDRESS_ID = AD.ADDRESS_ID
ORDER BY P.PERSON_ID;

SELECT *
FROM ALCOHOLIC_V;


CREATE OR REPLACE VIEW SPECIALIST_V AS
    SELECT P.PERSON_ID,
       P.PERSON_ID_NUMBER,
       P.FIRST_NAME,
       P.LAST_NAME,
       P.TEL_N,
       AD.ADDRESS_ID, TOWN, STREET, HOUSE_N, POST_CODE,
       S.PRACTISE, AMBULANCE_ADDRESS
FROM PERSON P
LEFT JOIN ADDRESS AD on P.ADDRESS_ID = AD.ADDRESS_ID
JOIN SPECIALIST S on P.PERSON_ID = S.PERSON_ID
ORDER BY P.PERSON_ID;

SELECT * FROM SPECIALIST_V;


CREATE OR REPLACE VIEW SPONSOR_V AS
    SELECT P.PERSON_ID,
       P.PERSON_ID_NUMBER,
       P.FIRST_NAME,
       P.LAST_NAME,
       P.TEL_N,
       AD.ADDRESS_ID, TOWN, STREET, HOUSE_N, POST_CODE

FROM PERSON P
LEFT JOIN ADDRESS AD on P.ADDRESS_ID = AD.ADDRESS_ID
WHERE P.PERSON_ID IN (
    SELECT A.SPONSOR
    FROM ALCOHOLIC A
    WHERE A.SPONSOR is not  null
    )
ORDER BY P.PERSON_ID;

SELECT * FROM SPONSOR_V;
