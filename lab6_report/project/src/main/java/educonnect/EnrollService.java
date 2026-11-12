package educonnect;

import java.sql.*;

public class EnrollService {
    public static String enrollStudentFromJava(int userID, int courseID) {
        String sql = "CALL EnrollStudent(?, ?, ?)";
        try (
            Connection conn = DBConnection.getConnection();
            CallableStatement cs = conn.prepareCall(sql)
        ) {
            cs.setInt(1, userID);
            cs.setInt(2, courseID);
            cs.registerOutParameter(3, java.sql.Types.VARCHAR);
            cs.execute();
            return cs.getString(3);
        } catch (SQLException e) {
            return "ERROR: " + e.getMessage();
        }
    }

    public static void getCourseReportFromJava(int courseID) throws SQLException {
        try (
            Connection conn = DBConnection.getConnection();
            CallableStatement cs = conn.prepareCall("CALL GetCourseReport(?)")
        ) {
            cs.setInt(1, courseID);
            boolean hasResultSet = cs.execute();
            if (hasResultSet) {
                try (ResultSet rs = cs.getResultSet()) {
                    System.out.println("Course Report for CourseID " + courseID + ":");
                    while (rs.next()) {
                        System.out.printf(" %-20s | %-12s | %s%n",
                            rs.getString("FullName"),
                            rs.getString("EnrollDate"),
                            rs.getString("GradeDisplay"));
                    }
                }
            } else {
                System.out.println("No results returned.");
            }
        }
    }
}
