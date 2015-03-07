NICARBingo is an iteration of a Twitter Bingo [experiment] created at a #newshack [hackathon] by [Daniel McLaughlin], [David Putney], and [Andrew Ba Tran]. 

It's a scavenger hunt bingo game, played exclusively through Twitter. It runs via Python and MySQL. It can be adapted to any theme or event-- the original test was for [@MBTABingo]. 

To play, tweet at the [@NICARBingo] account and the bot will randomly generate squares and tweet a photo of the card and a unique URL with an interactive version of the card back at you. 

Each square on the card contains a description of something a NICAR attendee might run across and an identifying hashtag. To claim a square, take a photo of it and tweet it through the Twitter app with the matching hashtag, mentioning [@NICARBingo]. The bot will fill in the square with the photo and send you an updated bingo card. Meanwhile, the leaderboard will keep track of those closest to getting a Bingo or list those who have already reached it and also list the latest dozen square submissions.

As we originally [wrote]: 

> People want to share their photos and have hashtag conversations with their friends and followers. News organizations are being left out.

> News Bingo is a structured way to get user-submitted photos that have been previously categorized. News coverage topics can be turned into a Twitter Bingo relatively easily. Events, Election campaigns, Concerts, etc.

> It's a way to get people to play in their own stream with minimal intrusion from a news site. But if they ever get the urge to learn more, they can follow their own card link to dive deeper into journalism.

# Getting started

*Note: [@NICARBingo] runs on an ubuntu server on digitalocean.com*

### Set up your server
Get the right libraries (You might need to apt-get some of these individually)
```sh
$ sudo apt-get update
$ sudo apt-get install -y mysql-server libmysqlclient-dev git python-pip python-dev phantomjs
$ sudo apt-get install python-mysqldb
$ sudo apt-get install mysql-server
```
Access the mysql shell with your login (your username might be root) and set up a mysql server named after the bingo game you want

```sh
$ mysql -u USER -pPASSWORD
mysql> create database nicarbingo
```
### Twitter
- Create a Twitter account
- Create New App
- Generate the API Keys and Access Tokens (Make sure access level is Read, Write)

### HTML template
- Download this repo
- ```nicar-bingo/website/static/siteart/star.svg``` - SVG for the logo found here
- ```nicar-bingo/website/static/templates/card.html``` and ```leaderboard.html``` - The markup for player cards and leaderboard
- ```nicar-bingo/website/static/css/bingo.css``` - Where to adjust the style
- edit ```daemon.py``` in ``` nicar-bingo``` and change the website on **line 249** to the domain you want (Right now it's nicarbingo.com)

### Credentials
- Create a file called config.json and copy over the contents of config-sample.json
- Fill out config.json with the MySQL database details and the Twitter handle’s API keys
- Note: mysql default host might be 127.0.0.1 depending on your settings

### Creating the squares
- Create a [spreadsheet] of goals following the included header format and export as a CSV
- Note: There must be at least 24 goals.
- Note: Only columns A and B must be filled in. The other columns are optional.
- Note: It is recommended that hashtags be no longer than 12 characters or they get cut off in the cards.
- Export the spreadsheet as a CSV file (```nameofcsv.csv```) and save it into the downloaded repo folder

### Setting up your mysql server
- Upload the repo with all your new files over to your server.
- cd into the nicar-bingo directory
- Import the bingo mysql schema: 
    - ```$ mysql -u USER -pPASSWORD nicarbingo < bingo.sql```
- Import the goals from the CSV to your mysql server:
    - ```$ python load_goals.py nameofcsv.csv```

### Bringing over Flask, Twitter bot files, etc
*Note: make sure you're in the nicar-bingo directory*
```sh
$ sudo pip install virtualenv
$ virtualenv ve
$ . ve/bin/activate
$ pip install -r requirements.txt
```
**Wait, wait, wait. You need to adjust a python file-- uploading image data causes unicode problems. Sorry. **

Go to ```nicarbingo/ve/lib/python2.7/site-packages/twitter/api.py``` and comment out the second line: ```from future import unicode literals```

###Run those beautiful python files (for testing)
First tab
(*Note: make sure you're in the root/nicar-bingo directory*)
```sh
$ . ve/bin/activate
$ python daemon.py
```
Second tab
(*Note: make sure you're in the root/nicar-bingo directory*)
```sh
$ . ve/bin/activate
$ cd/website
$ python website.py
```
###Run those beautiful python files (forever)
```sh
$ . ve/bin/activate
$ nohup python daemon.py &
$ cd/website
$ nohup python website.py &
```

[Daniel McLaughlin]:http://www.twitter.com/mclaughlin
[David Putney]:http://www.twitter.com/putneydm
[Andrew Ba Tran]:http://www.twitter.com/abtran
[@NICARBingo]:http://www.twitter.com/nicarbingo
[experiment]:https://github.com/danielsmc/twitter-bingo
[hackathon]:https://blog.twitter.com/2014/hacking-journalism-at-the-mit-media-lab
[wrote]:http://hackingjournalism.challengepost.com/submissions/24265-news-bingo
[@mbtabingo]:http://www.twitter.com/mbtabingo
[leaderboard]:http://nicarbingo.com:5000/leaderboard
[new app]:https://apps.twitter.com
[spreadsheet]:https://docs.google.com/spreadsheets/d/1Ywr7XJ2QQVSeAvDBAfIo87fUYaVgj0NbOn5d4XkXMmA/edit?usp=sharing
