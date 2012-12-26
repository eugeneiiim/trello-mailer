Note (12/25/12) - you can achieve the same thing more easily via Zapier: https://zapier.com/zapbook/trello/flowdock/2796/flowdock-message-for-trello-card/


trello-mailer
=============

Mails an email address and/or posts to Flowdock when new trello cards are created. Depends on Redis and Sendgrid. Built for deployment to Heroku with a scheduled task.

Required environment variables:
* TRELLO_KEY
* TRELLO_TOKEN
* TRELLO_BOARD_ID
* REDISTOGO_URL
* SENDGRID_PASSWORD
* SENDGRID_USERNAME

Optional environment variables:
* EMAIL_ADDR - an email will be sent to this address.
* FLOWDOCK_TOKEN - a flowdock notification will be posted to the board with this API token.
