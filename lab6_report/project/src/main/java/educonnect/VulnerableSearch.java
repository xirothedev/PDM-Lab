package educonnect;

import java.sql.*;

public class VulnerableSearch {
    // TEMPORARY VULNERABLE VERSION — for demonstration only (Task 3.1)
    public static void vulnerableSearch(String input) throws SQLException {
        String sql = "SELECT UserID, FullName, Role FROM Users WHERE FullName = '" + input + "'";
        try (
            Connection conn = DBConnection.getConnection();
            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery(sql)
        ) {
            System.out.println("=== Results for input: " + input + " ===");
            while (rs.next()) {
                System.out.println(rs.getInt("UserID") + " | " + rs.getString("FullName"));
            }
            System.out.println("=== End ===");
        }
    }
}
