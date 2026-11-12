package educonnect;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class StudentDAO {

    /**
     * Returns a list of students matching the given role filter.
     * Safe against SQL injection. Closes all resources correctly.
     */
    public static List<String[]> getStudentsByRole(String role) {
        List<String[]> results = new ArrayList<>();
        String sql = "SELECT UserID, FullName, Email FROM Users WHERE Role = ? ORDER BY FullName";

        try (
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setString(1, role);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    results.add(new String[] {
                        String.valueOf(rs.getInt("UserID")),
                        rs.getString("FullName"),
                        rs.getString("Email")
                    });
                }
            }
        } catch (SQLException e) {
            System.err.println("Query failed: " + e.getMessage());
        }
        return results;
    }

    // Task 2.3: never return a ResultSet; process inside and return a List.
    public static List<String[]> getAllUserNames() {
        List<String[]> results = new ArrayList<>();
        try (
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement("SELECT * FROM Users");
            ResultSet rs = ps.executeQuery()
        ) {
            while (rs.next()) {
                results.add(new String[] { rs.getString("FullName") });
            }
        } catch (SQLException e) {
            System.err.println("Query failed: " + e.getMessage());
        }
        return results;
    }

    // Bad example kept for demonstration (Task 2.3) - returns invalid ResultSet.
    public static ResultSet getBadResultSet() throws SQLException {
        Connection conn = DBConnection.getConnection();
        PreparedStatement ps = conn.prepareStatement("SELECT * FROM Users");
        ResultSet rs = ps.executeQuery();
        conn.close(); // close connection BEFORE returning ResultSet
        return rs;    // ResultSet is now invalid
    }
}
