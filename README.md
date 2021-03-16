# Slack Wormhole Functions

## Setting

Store Slack API Token with Secret Manager

```
$ echo $SLACK_API_TOKEN | gcloud secrets create slack-api-token --data-file=-
```

### Environments

```
TOKEN_NAME: Name of Slack API TOKEN in Secret Manager

```
