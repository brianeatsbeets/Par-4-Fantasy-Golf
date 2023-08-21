# Par-4-Fantasy-Golf

Par 4 Fantasy Golf is a fantasy betting app for professional golf where you bet against friends instead of against the house. It was proposed by a friend of mine as a replacement for a complicated Excel document he was keeping to track picks and tournament results. The basic components are leagues and tournaments; leagues contain tournaments and users, and tournaments contain athletes and user picks. When creating a tournament, you can import odds data from a Google Sheet, and you can set a budget for making selections. Before a tournament begins, league members can select the athletes who they think have the greatest chance of winning, and those selections are solidified once the tournament begins. As the tournament progresses, scoring data will periodically be imported from an ESPN API, and league member rankings will be updated based on how well their selected athletes are performing. After a tournament ends, the winner is decided and the league rankings (based on tournament wins) are updated.

This application and its infrastructure are built with a tiny userbase in mind - this is purely a project for friends, and it uses the free tier of Firebase for data storage, which has very restrictive usage limits. Data fetching efficiency and UI design are currently structured for an MVP and will be refined and updated in future releases.

Features:
- Authentication and database via Firebase
- Custom collection/table view cells and layout
- Diffable data sources
- Real-time view controller data source updates via Combine subscription
- Data fetching from ESPN API using async/await and decoding into usable models
- Import and parse from Google Sheets (csv)
