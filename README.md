trello-mailer
=============

Mails an email address when new trello cards are created. Depends on Redis and Sendgrid. Built for deployment to Heroku with a scheduled task.

Required environment variables:
* TRELLO_KEY
* TRELLO_TOKEN
* TRELLO_BOARD_ID
* EMAIL_ADDR
* REDISTOGO_URL
* SENDGRID_PASSWORD
* SENDGRID_USERNAME
