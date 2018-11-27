USE school;

--Show number of courses for each student
SELECT StudentID, COUNT(CourseID) as NumCourses
FROM Enrollment
GROUP BY StudentID
ORDER BY NumCourses DESC, StudentID;
GO


--Show number of students in each course.
SELECT c.CourseID, c.CourseName, Quarter, COUNT(*) AS Enrollment
FROM COURSES c INNER JOIN Enrollment e ON c.courseID=e.CourseID
GROUP BY Quarter, c.CourseID, c.CourseName
ORDER BY Quarter, CourseID;
GO
