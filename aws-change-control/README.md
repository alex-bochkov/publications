<h1>AWS Change Control</h1>
<p>One of challenges I always face in cloud environments is staying on top of changes that affect services I own or responsible for. In large teams, even with strict change control procedures, engineers tend to quietly make small changes that may result in unexpected environment behaviour.</p>
<p>This set of scripts is an example of the process that notifies you via email each time the change was made in your objects.</p>
<p>AWS has tools to solve this problem but, as a database engineer, I wanted to solve it my way.</p>
<ul>
  <li>SQL Server 2017+ is required because of usage JSON conversion feature.</li>
  <li>Example includes change control for instances and security groups only.</li>
  <li>Objects are filtered by "Owner: DBA" tag.</li>
</ul>
