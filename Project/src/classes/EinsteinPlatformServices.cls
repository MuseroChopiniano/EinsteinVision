public class EinsteinPlatformServices{
    public String getAccessToken() {
        // Ignore the File upload part and "jwt.pkcs" if you used a Salesforce certificate to sign up 
        // for an Einstein Platform account
        ContentVersion base64Content = [
            SELECT Title, VersionData 
            FROM ContentVersion 
            WHERE Title='einstein_platform' 
            LIMIT 1
        ];
        String keyContents = base64Content.VersionData.tostring();
        keyContents = keyContents.replace('-----BEGIN RSA PRIVATE KEY-----', '');
        keyContents = keyContents.replace('-----END RSA PRIVATE KEY-----', '');
        keyContents = keyContents.replace('\n', '');

        // Get a new token
        JWT jwt = new JWT('RS256');
        
        jwt.pkcs8 = keyContents;
        jwt.iss = 'developer.force.com';
        jwt.sub = 'suarez.gastonalejandro@gmail.com';
        jwt.aud = 'https://api.einstein.ai/v2/oauth2/token';
        jwt.exp = '3600';
        String access_token = JWTBearerFlow.getAccessToken(jwt);
        system.debug(access_token);
        return access_token;
    }

    public Dataset__c createDataset(string urlImage){
        Dataset__c aDataset = new Dataset__C();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://api.einstein.ai/v2/vision/datasets/upload/sync');
        req.setHeader('Authorization','Bearer ' + getAccessToken());
        req.setHeader('Cache-Control','no-cache');
        req.setHeader('Content-Type',HttpFormBuilder.GetContentType());
        system.debug(req);
        system.debug(req.getHeader('Authorization'));
        system.debug(req.getHeader('Cache-Control'));
        system.debug(req.getHeader('Content-Type'));
        string contentType = HttpFormBuilder.GetContentType();
       
        //  Compose the form 
        string form64 = '';
        form64 += HttpFormBuilder.WriteBoundary();
        form64 += HttpFormBuilder.WriteBodyParameter('type', 'image');
        form64 += HttpFormBuilder.WriteBoundary();
        form64 += HttpFormBuilder.WriteBodyParameter('path', urlImage);
        form64 += HttpFormBuilder.WriteBoundary(HttpFormBuilder.EndingType.CrLf);

        blob formBlob = EncodingUtil.base64Decode(form64);
        req.setBodyAsBlob(formBlob);

        Http http = new Http();
        HttpResponse response = http.send(req);
        if(response.getStatusCode() == 200){
            system.debug(response.getBody());
            map<string,object> myMap =  (Map<String, Object>) json.deserializeUntyped(response.getBody());
            aDataset.name = (string) myMap.get('name');
            aDataset.totalExamples__c = (integer) myMap.get('totalExamples');
            aDataset.totalLabels__c = (integer) myMap.get('totalLabels');
            aDataset.available__c = (boolean) myMap.get('available');
            aDataset.statusMessage__c = (string) myMap.get('statusMsg');
            aDataset.id__C = string.valueOf((integer) myMap.get('id'));
            aDataset.type__c = (string) myMap.get('type');
        }
        return aDataset;
        /*
        CUrl command
        curl -X POST -H "Authorization: Bearer <TOKEN>" 
        -H "Cache-Control: no-cache" -H "Content-Type: multipart/form-data" 
        -F "type=image" -F "path=http://einstein.ai/images/mountainvsbeach.zip" 
        https://api.einstein.ai/v2/vision/datasets/upload/sync
        */
    }
}