package educonnect;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class SafeQueryRunner {
    /**
     * Returns students whose FullName matches nameInput.
     * Safe against SQL injection. Closes all resources correctly.
     */
    public static List<String[]> searchStudentByName(String nameInput) {
        List<String[]> results = new ArrayList<>();
        String sql = "SELECT UserID, FullName, Email FROM Users " +
                     "WHERE Role = 'student' AND FullName = ?";

        try (
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setString(1, nameInput);
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
            throw new RuntimeException("Query failed: " + e.getMessage(), e);
        }
        return results;
    }
}
