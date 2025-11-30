<!-- Here in my app when user reserve is gonna going to the history page if u check my whol code u will see all the logic of it : 
""
and there in the page of the history 
we can note the players as I did there 
now we have new thing to do : 
after all player joing to the reserve L( 4 players.) 
and the match is Dont 
how we know the match ( reserve is Done ) :  "we know that by when reserv match is over time that they choise " 

so after match Done we need to make user put there scoore 
every player ( user ) play the match in that reserve can put the scoore of the match 
so all the condition of this operstion is gonna be like this :   
Task: Score Management After a Padel Match
Objective:
Allow players to enter and validate the score of a match (public or private) within 24 hours after the end of the match.
Process:
Score Entry:
Upon the next login to the app, each player who participated in the match can enter the score.
Score entry is only possible within 24 hours following the end of the match.
Notification and Validation:
As soon as a player submits a score, the other players receive a notification inviting them to either validate or dispute the score.
Automatic Validation:
If a player submits a score and no one disputes it, the score is automatically validated.
If a player submits a score and all others validate it, the score is validated.
Dispute Management:
If one or more players dispute the score, they can enter their version of the score.
After the 24-hour deadline:
If 3 out of 4 players agree on a score and 1 disputes, the score is validated.
If 2 players validate and 2 dispute, the score becomes invalid and requires manual intervention (option to be defined).
Special Case:
If one player submits the score and no other player takes action (neither validates nor disputes), the score is automatically finalized after 24 hours.
Suggested Technical Notes:
Create a score status for each match: Pending, Validated, Disputed.
Manage push or in-app notifications to inform players.
Record all entries for audit and history purposes.



""



Do it by the right way and if u fine any issues  fix it in ur way 
 -->
