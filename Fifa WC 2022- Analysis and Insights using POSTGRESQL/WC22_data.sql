-- create tables 

--WC Groups 

/*
CREATE TABLE WCgroup (
		Group_ID		varchar(20) Primary key,
		Team_Name		varchar(20) not null,
		Points_Gained	int         NOT NULL,
		Positions		int         NOT NULL,
		Status			varchar(20) NOT NULL,
		Team_ID			int         NOT NULL
);

--WC Matches 

CREATE TABLE WCmatches (
			Match_ID	  int         PRIMARY KEY , 
			"Date"		  Date        NOT NULL , 
			Round	      varchar(20) NOT NULL,
			Home_Team	  varchar(20) NOT NULL,
			Away_Team	  varchar(20) NOT NULL,
			"Result"	  varchar(20) NOT NULL,
			Stadium_Name  varchar(40) NOT NULL,
			Stadium_ID	  varchar(20) NOT NULL
)

CREATE TABLE WCstadiums (
	Stadium_ID		varchar(20) PRIMARY KEY,
	Stadium_Name	varchar(40) NOT NULL,
	Round			varchar(20) NOT NULL,
	"Location"		varchar(20) NOT NULL,
	Attendance 		int         NOT NULL,
	Match_ID		int         NOT NULL
)


CREATE TABLE WCGoals (
		Goal_ID     	int         PRIMARY KEY , 
		Goal_Scorer	    varchar(20) NOT NULL,
		Scored_Against  varchar(20) NOT NULL,
		"Round"			varchar(20) NOT NULL,
		Goal_Minute		varchar(20) NOT NULL,
		Minute_Format	varchar(20) NOT NULL,
		Team_ID			int         NOT NULL,
		Match_ID		int         NOT NULL 
)

ALTER TABLE WCgoals 
ALTER COLUMN Minute_Format TYPE varchar(40);

ALTER TABLE WCgoals 
ALTER COLUMN Goal_Scorer TYPE varchar(40)

CREATE TABLE WCteams ( 
				Team_ID			int  PRIMARY KEY, 
				Team_Name		Varchar(20),
				Wins			int, 
				Losses			int, 
				Draws			int ,
				Goals_Scored	int ,
				Goals_Conceded	int ,
				Clean_Sheets	int ,
				Yellow_Cards	int ,
				Red_Cards	int ,
				Highest_Finish	Varchar(20),
				Group_ID	Varchar(20)
)

ALTER TABLE WCteams
ADD CONSTRAINT Fk_Group_id FOREIGN KEY (Group_ID) REFERENCES WCgroup(Group_ID) 

ALTER TABLE WCgoals
ADD CONSTRAINT Fk_match_id FOREIGN KEY (Match_ID) REFERENCES WCmatches(Match_id) 

ALTER TABLE WCstadiums
ADD CONSTRAINT Fk_Match_id FOREIGN KEY (Match_ID) REFERENCES WCmatches(Match_id) 

*/

--Table info checking 
	SELECT * FROM  Wcgroup 
	SELECT * FROM  Wcstadiums
	SELECT * FROM  Wcmatches 
	SELECT * FROM  Wcteams 
	SELECT * FROM  Wcgoals

--DQL -- 

/* 1. stadiums that hosted more matches */ 

	SELECT stadium_name , COUNT(match_id) AS match_count
	FROM WCmatches
	GROUP BY  stadium_name 
	ORDER BY  COUNT(match_id) DESC ; 

/* 2. Proportion of teams that reached atleast quarterfinal , their win% in tournament and also their 
position in the group stage*/

		WITH wc AS
		( SELECT wct.team_name,wct.wins,
		 wcg.positions AS group_rank,
		 CAST((wct.wins+wct.losses+wct.draws) AS DECIMAL) AS matches_played 
			FROM Wcteams wct 
			INNER JOIN Wcgroup wcg ON 
		 	wct.team_id = wcg.team_id
			WHERE wct.highest_finish IN ('Quarter Final','Semi Final',
									 'Final','CHAMPIONS') 
			AND wcg.status = 'Qualified' )       
		
		SELECT wc.team_name , wc.group_rank,
		ROUND((wc.wins *100/ wc.matches_played),2) AS win_percent
		FROM wc 
		ORDER BY  round((wc.wins *100/ wc.matches_played),2) DESC;

'note: 7 out of 8 teams that reached quarter-finals topped their group table.' 


/* 3. top 5 goal scorers along with their group and knock out goals */ 

		SELECT goal_scorer , SUM(CASE 
								WHEN "Round" = 'Group Stage' THEN 1 
								 ELSE 0 
								 END) AS GroupStage_goals, 
							 SUM(CASE 
								WHEN "Round" NOT IN ('Group Stage') THEN 1 
								 ELSE 0
								 END) AS knockout_goals, 
							COUNT(goal_id) AS total_goals 
		FROM Wcgoals
		GROUP BY  goal_scorer
		ORDER BY COUNT(goal_id) DESC
		LIMIT 5;

--Kylian mbappe is the golden boot winner 

/* 4) Rank top 5 teams with highest number of foul cards (yellow and red), incase of a tie sort them by least goals conceded */ 

		WITH foul AS 
		(SELECT team_name , 
		SUM(yellow_cards+red_cards) AS fouls,
		SUM(goals_conceded) AS goals_conceded
		FROM Wcteams
		GROUP BY team_name)

		SELECT foul.* , 
		ROW_NUMBER() OVER(ORDER BY foul.fouls DESC ,foul.goals_conceded ASC )
		AS "Rank" 
		FROM foul 
		LIMIT 5;

/* 5  Top 6 countries that played most number of games */ 

		SELECT team.team_name , 
		COUNT(team.team_name) AS matches_played 
		FROM 
			(SELECT wcg.team_name ,wcm.home_team ,wcm.away_team  
			FROM wcgroup wcg 
			JOIN wcmatches wcm 
			ON wcg.team_name = wcm.home_team 
			OR wcm.away_team = wcg.team_name) AS team
		GROUP BY team.team_name
		ORDER BY COUNT(team.team_name) DESC , team.team_name 
		LIMIT 6;

--An additional game played between croatia and morocco for 3rdspot 

/* 6. Query the total crowd for group and knock_out games along with the avg crowd/game at each stage */ 
 
      --View creation 
	  
      CREATE VIEW stadium_info AS          
	  (SELECT  stadium_id , stadium_name , 
	  (CASE 
		 WHEN round = 'Group Stage' THEN 'groups' 
		ELSE 
			  'knockouts' END) AS stage , match_id,attendance
	  FROM Wcstadiums)   
	  
	  SELECT stage , COUNT(match_id) AS matches_by_stage,
	  SUM(attendance) AS attendance_by_stage ,
	  SUM(attendance)/COUNT(match_id) AS avg_attendance_game 
	  FROM stadium_info 
	  GROUP BY stage 
	  ORDER BY SUM(attendance) DESC ;
   

/* 7 Query for the top 5 teams that attracted more crowd (their average crowd/game) & number of games played.*/
 
      CREATE VIEW team_crowd AS 
	  (SELECT team.team_name,
	   SUM(si.attendance)/COUNT(si.match_id) AS avg_crowd,
	   COUNT(si.match_id) AS matches_played
	   FROM stadium_info si
	   INNER JOIN (SELECT wcg.team_name ,wcm.match_id 
	  				FROM wcgroup wcg 
	  				JOIN wcmatches wcm 
      				ON wcg.team_name = wcm.home_team 
	  				OR wcm.away_team = wcg.team_name 
	  				ORDER BY match_id) AS team
	   ON team.match_id = si.match_id
	   GROUP BY team.team_name) 
	   
	   SELECT * FROM TEAM_CROWD 
	   ORDER BY avg_crowd DESC 
	   LIMIT 5 ;  
	   
	   --TEAMS LIKE MEXICO AND SAUDI HAD GREATER AVG CROWD AS THEY PLAYED CRUCIAL ALONG SIDE ARGENTINA IN GROUP STAGE
	   --THEY MAY NOT BE CROWD PULLERS IN REALITY , HENCE WE NEED TO LOOK IN TO TEAMS THAT 1 PLAYED KNOCK OUT GAME ATLEAST
	   
	   SELECT * FROM TEAM_CROWD 
	   WHERE matches_played >= 4
	   ORDER BY avg_crowd DESC 
	   LIMIT 5;
	   
	   --fact that finalist france not in top 5 

/* 8.  top 5 teams who achieved more clean sheets & their % of clean sheets . */
	
		SELECT wcm.team_name, wcm.clean_sheets,
		ROUND((wcm.clean_sheets*100.0 / tc.matches_played),2) as clean_sheets_percent
		FROM WCteams wcm 
		INNER JOIN Team_crowd tc 
		ON tc.team_name = wcm.team_name 
		order by wcm.clean_sheets DESC
		LIMIT 5;
	
/* 9. Teams with NEGATIVE Goal differences and failing to reach knockoutstages */ 

       SELECT team_name , 
	   (goals_scored-goals_conceded) AS GOAL_DIFF 
	   FROM WCteams
	   WHERE goals_scored < goals_conceded 
	   AND highest_finish = 'Group Stage'
	   ORDER BY goals_scored-goals_conceded ASC ;
	   
	   --11 out of 17 teams with Negative GD failed to reach knockouts , defences win you tournaments . 


/* 10 count the number of Goals that we scored in normal time , extra time and additional time during various stages of  
      the tournament. */ 
	  
	  CREATE VIEW Goals_by_Stage AS (
	  SELECT "Round", SUM(CASE 
					 	WHEN minute_format = 'Normal Time' THEN 1 ELSE 0 END) AS Norm_time_Goals , 
					  SUM(CASE 
					 	WHEN minute_format = 'Additional Time' THEN 1 ELSE 0 END) AS Addn_time_goals,
					  SUM(CASE 
					 	WHEN minute_format ilike '%Extra Time%' THEN 1 ELSE 0 END) AS Extra_time_goals
	  FROM WCGoals  
	  GROUP BY "Round")
	  
	  SELECT * FROM (
	  SELECT * , 
	  (Norm_time_Goals+Addn_time_goals+Extra_time_goals) AS Total_goals
	  FROM Goals_by_Stage ) AS TG 
	  ORDER BY TG.Total_goals DESC 
	  
/* 11 Query the goals scored in each stage of the game along with the goals/match ratio of that particular stage */	  
   
     WITH CTE AS (
     SELECT gbs."Round" , Mch.Match_count ,
	 (gbs.Norm_time_Goals+gbs.Addn_time_goals+gbs.Extra_time_goals) AS Total_Goals 
	 FROM Goals_by_Stage gbs
	 INNER JOIN (SELECT Round AS stage,COUNT(match_id) AS Match_count 
	 			 FROM WCmatches 
	 			 GROUP BY Round) Mch 
	 ON gbs."Round" = Mch."stage" ) 
	 
	 SELECT cte."Round" , cte.total_goals , cte.match_count, 
	 Round((total_goals::Decimal )/match_count ,2) AS Goal_per_game 
	 FROM cte 
	 ORDER BY Round((total_goals::Decimal )/match_count ,2) DESC ;

/* 12. Query the Names of players who scored goals in every stage of tournament */ 
	  
      SELECT goal_scorer FROM Wcgoals 
	  GROUP BY  goal_scorer 
	  HAVING Count(distinct "Round") = (SELECT COUNT(DISTINCT "Round") FROM wcgoals
									   WHERE "Round" NOT in ('3rd Place Playoff') )
  
      




 