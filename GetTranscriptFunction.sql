USE School;
GO

--------------------------------------------------------------

DROP FUNCTION IF EXISTS dbo.fcnGetTranscript;
GO

--------------------------------------------------------------

CREATE FUNCTION dbo.fcnGetTranscript (@id int)
RETURNS TABLE
AS
RETURN(

SELECT
	s.FirstName + ' ' + s.LastName AS [Student Name],
	q.QuarterName as [Quarter],
	TRIM(c.Subject) + ' ' + TRIM(STR(c.CourseNum)) as [Course Number],
	c.CourseName as [Course],
	e.Grade as [Course Grade]
FROM Enrollment e
	INNER JOIN Students s ON e.StudentID=s.ID
	INNER JOIN Courses c ON c.CourseID=e.CourseID
	INNER JOIN Quarters q on e.Quarter=q.QuarterID
WHERE s.ID=@id
);
GO

--------------------------------------------------------------

--EXAMPLE #1: Test out the function
SELECT * FROM dbo.fcnGetTranscript(1857);

GO

/* 
EXAMPLE #2: This is really cool! We're going to use a cross apply to run this
on the entire student table but only for students who are currently
enrolled for Winter 2019 quarter (Quarter=2 in Enrollment table) */

SELECT FirstName, LastName, [Quarter], [Course], [Course Grade]
FROM Students s CROSS APPLY 
	dbo.fcnGetTranscript(s.ID)
WHERE s.ID IN
	(SELECT DISTINCT StudentID FROM Enrollment
	WHERE Quarter=5
	)
ORDER BY s.LastName, s.FirstName, [Quarter], [Course];
 