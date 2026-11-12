package educonnect;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class StudentSearch {
    // Partial-name search using StudentProgressReport view.
    public static List<String[]> searchByName(String nameInput) {
        List<String[]> results = new ArrayList<>();
        String sql = "SELECT StudentName, TotalEnrolled, AverageGrade " +
                     "FROM StudentProgressReport WHERE StudentName LIKE ?";

        String pattern = "%" + nameInput + "%"; // safe: pattern is the parameter value
        try (
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)
        ) {
            ps.setString(1, pattern);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    results.add(new String[] {
                        rs.getString("StudentName"),
                        String.valueOf(rs.getInt("TotalEnrolled")),
                        String.valueOf(rs.getDouble("AverageGrade"))
                    });
                }
            }
        } catch (SQLException e) {
            System.err.println("Query failed: " + e.getMessage());
        }
        return results;
    }
}
