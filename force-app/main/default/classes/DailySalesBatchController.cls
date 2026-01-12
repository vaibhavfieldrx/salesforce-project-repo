public class DailySalesBatchController {

    public static List<Opportunity> salesList { get; set; }
    public String reportDate { get; set; }

    public DailySalesBatchController() {

        reportDate = String.valueOf(Date.today());

        salesList = [
            SELECT Name, Amount, CloseDate
            FROM Opportunity
            WHERE StageName = 'Closed Won'
            AND CloseDate = TODAY
        ];
    }
}