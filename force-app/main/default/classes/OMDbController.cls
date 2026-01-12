public with sharing class OMDbController {
    @AuraEnabled(cacheable=true)
    public static String searchMovies(String search, String type, String pageNo) {
        String apiKey = 'fe0e305b'; // your actual API key
        String endpoint = 'https://www.omdbapi.com/?s=' + EncodingUtil.urlEncode(search, 'UTF-8') +
                          '&type=' + EncodingUtil.urlEncode(type, 'UTF-8') +
                          '&page=' + EncodingUtil.urlEncode(pageNo, 'UTF-8') +
                          '&apikey=' + apiKey;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            throw new AuraHandledException('Failed OMDb Call: ' + res.getStatus());
        }
    }
}