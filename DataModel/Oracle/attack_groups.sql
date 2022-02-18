DROP table RESEARCH.attack_groups

CREATE TABLE RESEARCH.attack_groups
(
GROUP_ID 				VARCHAR2(20 CHAR),
GROUP_NAME				VARCHAR2(500 CHAR),
GROUP_DESCRIPTION		VARCHAR2(500 CHAR),
GROUP_COUNTRY			VARCHAR2(100 CHAR),
YEAR_OF_ORIGIN			NUMBER(4),
created_string			VARCHAR2(20 CHAR),
last_modified_string	VARCHAR2(20 char),
created					DATE,
last_modified			DATE
);