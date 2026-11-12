package educonnect;

import java.sql.*;
import java.util.List;

public class BrokenQueryRunner {
    // THIS METHOD HAS A SQL INJECTION VULNERABILITY
    public static void searchStudentByName(String nameInput) {
        String sql = "SELECT UserID, FullName, Email FROM Users " +
                     "WHERE Role = 'student' AND FullName = '" + nameInput + "'";

        try {
            Connection conn = DBConnection.getConnection();
            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery(sql);

            while (rs.next()) {
                System.out.println(rs.getInt(1) + " | " +
                                   rs.getString(2) + " | " +
                                   rs.getString(3));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
