-- This file contains the stored procedures for the school database.

--------------------------------------------------------------------------
-- Show enrollments for students having more than x classes
--------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS dbo.spStudentOverload;
GO

CREATE PROC dbo.spStudentOverload (@limit int, @quarter int)
AS
BEGIN

SELECT s.FirstName, s.LastName, CAST(c.Subject AS char(4)) + CAST(c.CourseNum AS char(4)) AS Class, c.CourseName
FROM Students s
	INNER JOIN Enrollment e ON s.ID=e.StudentID
	INNER JOIN Courses c ON c.CourseID = e.CourseID
WHERE s.ID IN (
	SELECT StudentID
	FROM Enrollment e
	WHERE e.[Quarter]=@quarter
	GROUP BY StudentID
	HAVING COUNT(StudentID) > @limit
	)
ORDER BY s.LastName, s.FirstName
END;

GO
--Test
EXEC dbo.spStudentOverload 4, 3;
GO

--------------------------------------------------------------------------
-- We are randomly enrolling students into a given class in a given quarter
-- Students will be randomly selected by patterns in the First Name, Last Name, and Student Number
--------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS dbo.spRandomEnrollment;
GO

CREATE PROC dbo.spRandomEnrollment (
	@CourseID int, @quarter int, 
	@numkey varchar(10)=NULL, 
	@fnkey varchar(5)=NULL,
	@lnkey varchar(5)=NULL
)
AS

INSERT INTO dbo.Enrollment(CourseID, StudentID, [Quarter])
	SELECT @courseID, ID, @quarter FROM Students
	WHERE StudentNum LIKE '%' + @numkey + '%'
	AND (LastName LIKE '%' + @lnkey + '%'
	OR FirstName LIKE '%' + @fnkey + '%')
;

GO




-- Double check that we'll enroll the expected number of students.
SELECT * FROM Students
	WHERE StudentNum LIKE '%7%'
	AND (LastName LIKE '%st%'
	OR FirstName LIKE '%D%')

-- Test the procedure
EXEC dbo.spRandomEnrollment 13,4,'7','st','D'

/*--------------------------------------------------------------------------
Get the transcript for a given student and quarter
--------------------------------------------------------------------------*/

USE School;
GO

DROP PROCEDURE IF EXISTS dbo.spGetTranscript;
GO

CREATE PROCEDURE spGetTranscript (@SID int, @quarter int)
AS

IF @quarter=0 
	SELECT 
		s.ID as StudentID,
		s.FirstName, s.LastName,
		e.CourseID as CourseID,
		c.CourseName as Course,
		e.[Quarter] as Term,
		e.Grade as GPA
	FROM Enrollment e 
		INNER JOIN Students s ON e.StudentID=s.ID
		INNER JOIN Courses c ON e.CourseID=c.CourseID
	WHERE s.ID=@SID
	ORDER BY Term, CourseID
 ELSE 
	SELECT 
		s.ID as StudentID,
		s.FirstName, s.LastName,
		e.CourseID as CourseID,
		c.CourseName as Course,
		e.[Quarter] as Term,
		e.Grade as GPA
	FROM Enrollment e 
		INNER JOIN Students s ON e.StudentID=s.ID
		INNER JOIN Courses c ON e.CourseID=c.CourseID
	WHERE s.ID=@SID AND e.Quarter=@quarter
	ORDER BY Term, CourseID
;

GO

EXEC dbo.spGetTranscript 1115, 0

-- Testing the procedure on 10 RANDOMLY SELECTED students

DECLARE @SID int;
DECLARE @counter smallint = 1;

WHILE @counter <= 10
BEGIN
	SET @SID = RAND()*1100+1000
	EXEC dbo.spGetTranscript @SID, 3
	SET @counter +=1;
END;
GO



SELECT * FROM Enrollment
WHERE Quarter=5;

EXEC dbo.spGetTranscript 1520, 0 --0 means any quarter


/**----------------------------------------------
We want to find all prerequisites that exist for a particular course
-------------------------------------------------**/

USE School;
GO

DROP PROCEDURE IF EXISTS dbo.spFindPrerequisites;
GO

CREATE PROCEDURE dbo.spFindPrerequisites (@CourseID int)
AS

SELECT CourseID, CourseName
FROM Courses
WHERE CourseID IN
(	SELECT PrerequisiteCourse 
	FROM Prerequisites 
	WHERE CourseID = @CourseID
)
;
GO

--Test The Procedure
EXEC dbo.spFindPrerequisites 902;
GO


----------------------------------------------------------
-- Let's find out who has not yet enrolled! --
----------------------------------------------------------

USE School;
GO
 
DROP PROCEDURE IF EXISTS spNotEnrolledYet;
GO

CREATE PROCEDURE spNotEnrolledYet(@quarter int)
AS
SELECT 
	ID as [Student ID], 
	StudentNum as [Student Number], 
	LastName + ', ' + FirstName AS [Student Name]
FROM Students s 
	LEFT JOIN Enrollment e ON s.ID=e.StudentID
WHERE s.ID NOT IN
(
	SELECT DISTINCT StudentID From Enrollment
	WHERE Quarter=@quarter
)
ORDER BY [Student Name]
;
GO

EXEC spNotEnrolledYet 5;




 
-------------------------------------------------------------------
--STORED PROCEDURE TO ASSIGN RANDOM NORMALLY DISTRIBUTED GRADES
--INPUT QUARTER, AND THE INTENDED MEAN AND STANDARD DEVIATION
--ENROLLMENT TABLE WILL BE RANDOMLY FILLED WITH NORMALLY DISTRIBUTED
--GRADES ACCORDING TO THAT FORMULA ON A SCALE OF 0 TO 4
-------------------------------------------------------------------

USE School;



  GO

DROP PROCEDURE IF EXISTS spRandomGrades;
GO
CREATE PROCEDURE spRandomGrades (@quarter int, @mean float, @sd float)
AS
DECLARE @i int;
DECLARE @start int;
DECLARE @end int;
SET @start = (
	SELECT MIN(EnrollmentID) FROM Enrollment 
	WHERE [Quarter] = @quarter);
SET @end = (
	SELECT MAX(EnrollmentID) FROM Enrollment 
	WHERE [Quarter] = @quarter);
SET @i = @start;
WHILE @i < @end
BEGIN
	UPDATE Enrollment
	SET Grade= CAST(
		((RAND() * 2 - 1) + (RAND() * 2 - 1) + (RAND() * 2 - 1)) * @sd + @mean
		AS Decimal(2,1))
	WHERE EnrollmentID=@i AND [Quarter]=@quarter;	
	SET @i = @i +1;
END;

UPDATE Enrollment SET Grade = 4 WHERE Grade >4;
UPDATE Enrollment SET Grade = 0 WHERE Grade <1;
;
GO

UPDATE Enrollment SET Grade = NULL WHERE Quarter=3;
GO

EXEC spRandomGrades 3, 2.6, 0.8;


GO