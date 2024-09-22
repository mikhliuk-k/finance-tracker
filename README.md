# finance-tracker

## PDF Parser

### Installation

```shell
cd pdf_parser
bundle install
```

### Testing
```bash
functions-framework-ruby --port=8080 --target=parse_pdf --signature-type=cloudevent

curl -m 550 -X POST http://127.0.0.1:8080/function-1 \
-H "Authorization: bearer $(gcloud auth print-identity-token)" \
-H "Content-Type: application/json" \
-H "ce-id: 1234567890" \
-H "ce-specversion: 1.0" \
-H "ce-type: google.cloud.storage.object.v1.finalized" \
-H "ce-time: 2020-08-08T00:11:44.895529672Z" \
-H "ce-source: //storage.googleapis.com/projects/_/buckets/finance-statements" \
-d '{
  "name": "folder/Test.cs",
  "bucket": "some-bucket",
  "contentType": "application/json",
  "metageneration": "1",
  "timeCreated": "2020-04-23T07:38:57.230Z",
  "updated": "2020-04-23T07:38:57.230Z"
}'
```

## Pivot Builder

### Installation

```shell
cd pivot_builder
bundle install
```

### Testing
```shell
functions-framework-ruby --port=8080 --target=parse_pdf --signature-type=http

curl -m 70 -X POST http://127.0.0.1:8080/pivot_builder \
-H "Authorization: bearer $(gcloud auth print-identity-token)" \
-H "Content-Type: application/json"
```
