<h1>Simple monitoring for AWS changes</h1>
<p>One of challenges I always face in cloud environments is staying on top of changes that affect services I own or responsible for keeping operational within the SLA. In large teams, even with strict change control procedures, engineers tend to quietly make small changes that may result in unexpected environment behavior.</p>
<p>This set of scripts is an example of the process that notifies you via email each time the change was made in your objects.</p>
<p>AWS has tools to solve this problem but, as a database engineer, I wanted to solve it my way.</p>
<ul>
  <li>SQL Server 2017+ is required because of usage JSON conversion feature.</li>
  <li>Example includes change control for instances and security groups only.</li>
  <li>Objects are filtered by "Owner: DBA" tag.</li>
</ul>
<h2>Examples:</h2>
<p>Server has been stopped:</p>
<p><img src="https://github.com/alekseybochkov/publications/blob/master/aws-change-control/server-has-been-stopped.png?raw=true" alt="Server has been stopped"></p>
<p>Instance type has been changed:</p>
<p><img src="https://github.com/alekseybochkov/publications/blob/master/aws-change-control/instance-type-has-been-changed.png?raw=true" alt="Instance type has been changed"></p>
<p>Security group changes:</p>
<p><img src="https://github.com/alekseybochkov/publications/blob/master/aws-change-control/security-group-changes.png?raw=true" alt="Security group changes"></p>
<p>Volumes attached:</p>
<p><img src="https://github.com/alekseybochkov/publications/blob/master/aws-change-control/volume-attached.png?raw=true" alt="Volumes attached"></p>
