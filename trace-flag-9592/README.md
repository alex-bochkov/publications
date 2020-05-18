<p>Original article in Russian: <a href="https://infostart.ru/public/1237484/">https://infostart.ru/public/1237484/</a></p>
<hr/>
<h1>[SQL Server] Using trace flag 9592 to compress traffic between synchronous AlwaysOn replicas</h1>
<p>
Recently, we encountered a performance problem when the additional load associated with writing a large data set caused significant latency in usual write traffic. The solution we found not only helped to reduce the impact of the new process on the main user traffic, but also significantly reduce the amount of network traffic between synchronous cluster replicas.
</p>

<p>
We use SQL Server AlwaysOn cluster with synchronous replicas for high availability and disaster recovery. The database cluster is running in AWS cloud with replicas in different data centers within the same region. When active replica crashes, the cluster automatically detects the problem and transfers user traffic to another server without any data loss.
</p>
<p>
The main disadvantage of this configuration is the need to write data to all synchronous replicas in availability group before the end of the user transaction. In our case, write operations are approximately 40% slower than if they were running on stand-alone server.<br/>
In addition, any delays in the network or additional load on the primary or secondary server directly affect user transactions.
</p>
<p>
In this particular situation a new process was added that wrote a large amount of data and had a disproportionate effect on the overall system performance.
<br/>
SQL Server wait statistics show that WRITELOG has increased slightly, while HADR_SYNC_COMMIT has increased disproportionally high.
</p>
WRITELOG - the wait / cost of writing to the transaction log on active replica.
<br/>
HADR_SYNC_COMMIT indicates the same operation but on the synchronous replica side.
</p>
<p><img style="border: 1px solid black;" src="https://github.com/alekseybochkov/publications/blob/master/trace-flag-9592/hadr-sync-commit-spikes.png?raw=true" alt=""/> </p>
<p>
so there is clearly an issue with transferring the data to the secondary replica.
<br/>
There can be many reasons - network issues, high CPU utilization on secondary replica, slow storage with the transaction log on the secondary replica, etc.
<br/>
We did not find any of these problems and decided to try to enable the traffic compression between synchronous replicas.
<br/>
<a href="https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/tune-compression-for-availability-group?view=sql-server-ver15">https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/tune-compression-for-availability-group?view=sql-server-ver15</a>
<p>
By default, compression is not used for synchronous replicas, but is enabled for asynchronous replicas.<br/>
Compression is generally not recommended for synchronous replicas, as this may require additional processor resources and have a generally negative effect.<br/>
After several experiments, we found that the traffic compression does not have a negative effect specifically in our situation, but it helps us to address the current problem.<br/>
I suspect that the type of servers we use for databases plays a significant role - the z1d instance type uses one of the fastest processors available in the AWS cloud.<br/>
Traffic compression reduced the amount of transmitted data between database replicas by about 70%, which also had a positive effect on costs - traffic between AWS data centers is not free even within the same region.
</p>
<p><img style="border: 1px solid black;" src="https://github.com/alekseybochkov/publications/blob/master/trace-flag-9592/network-traffic-secondary-node-trace-flag-9592.png?raw=true" alt=""/> </p>

<p>
I would not recommend using this trace flag by default for everyone - it all depends on your specific configuration and it should be tested on a real working system in a controlled manner.
<br/>
For testing, you can use these commands:
</p>
<pre>
-- get list of used trace flag
DBCC TRACESTATUS;

-- enable trace flag for all processes
DBCC TRACEON (9592, -1);

-- disable trace flag for all processes
DBCC TRACEOFF (9592, -1);
</pre>
<p>
To turn this option on permanently it is better to add it to the command line:
</p>
<p><img style="border: 1px solid black;" src="https://github.com/alekseybochkov/publications/blob/master/trace-flag-9592/trace-flag.png?raw=true" alt=""/> </p>