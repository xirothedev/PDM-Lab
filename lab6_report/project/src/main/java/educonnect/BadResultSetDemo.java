package educonnect;

import java.sql.ResultSet;
import java.sql.SQLException;

public class BadResultSetDemo {
    public static void main(String[] args) {
        try {
            ResultSet rs = StudentDAO.getBadResultSet();
            while (rs.next()) {
                System.out.println(rs.getString("FullName"));
            }
        } catch (SQLException e) {
            System.err.println("SQLException: " + e.getMessage());
            System.err.println("SQLState: " + e.getSQLState() + " ErrorCode: " + e.getErrorCode());
        }
    }
}
