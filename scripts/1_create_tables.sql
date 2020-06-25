
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