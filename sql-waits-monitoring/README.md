<p>Original article in Russian: <a href="https://infostart.ru/public/920571/">https://infostart.ru/public/920571/</a></p>
<hr/>
<h1>High level SQL Server health monitoring</h1>
<p>
These scripts are just another attempt to “reinvent the wheel” in SQL Server waits monitoring which we are using in glassdoor.com.
I think that the absolute majority of database engineers are familiar with the concept of wait statistics in MS SQL Server - SQL Server tracks in detail the resource consumption and the duration of internal processes and allows the user to get cumulative values ​​from the server start or reset of statistics.</p>
<p>The Glassdoor website relies on MS SQL Server a lot, so it is important to ensure uninterrupted operation and the fastest response to possible changes.</p>
<p>All serious database monitoring systems have the ability to collect wait statistics  and build necessary report. For numerous reasons, we were not satisfied with what we get out of the box and it was decided to implement our own parallel data collection and visualization process.</p>
<p>The solution consists of three parts:
</p>
<ul>
<li>SQL Agent Task, which continuously collects accumulated statistics on each server. Every 15 seconds, the difference between the current and previous statistics is calculated and recorded in the local database table (stored procedure [Monitor]. [CollectWaitStatistics]).</li>
<li>A centralized server for collecting statistics from all servers and sending data to ElasticSearch (the other three files).</li>
<li>ElasticSearch + Kibana for storing, analyzing and visualizing data.</li>
</ul>
<h3>How is this data used?</h3>
<p>
We do not have any alerts triggered based on this data. Not all deviations are problems, and if this is a problem, the central monitoring system will alert us.</p>
<p>The main dashboard has separate graphs for each database cluster. It is constantly visible to all and is updated every minute.
One glance at it is enough to say that a database cluster is healthy or having issues.
<p>This is very simple but heavily used solution.</h3>
</p>
