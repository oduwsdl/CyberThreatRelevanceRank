DROP table RESEARCH.cwe;

CREATE TABLE RESEARCH.CWE
(
CWE_ID 						VARCHAR2(20 CHAR),
NAME						VARCHAR2(200 CHAR),
DESCRIPTION					VARCHAR2(4000 CHAR),
LIKELIHOOD_OF_EXPLOIT		VARCHAR2(100 CHAR)
);