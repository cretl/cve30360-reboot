# cve30360-reboot
<h2>TL;DR</h2>
<p>
Reboot a Hitron Technologies CVE-30360 cable modem with a simple Bash script.<br />
Only Bash, curl, jq and logger are needed.
</p>

<h2>Info</h2>
<p>
With this simple Bash script you can reboot a Hitron Technologies CVE-30360 cable modem.
</p>

<h3>Script</h3>
<h4>Dependencies</h4>
<p>
Bash, curl, jq and logger.
Just install with e.g. <code>apt install bash curl jq logger</code>
</p>

<h4>Installation</h4>
<ol>
<li>Just copy the script to a file.</li>
<li>Edit the settings part in the script.</li>
<li>Make the file executeable (e.g., with <code>chmod +x</code>).</li>
<li>Run the script: <code>./reboot_cve30360_modem.sh</code></li>
</ol>

<h4>Configuration</h4>
<p>The variables <code>PATH</code>, <code>modemIp</code>, <code>loginUsername</code> and <code>loginPassword</code> need to be adjusted.<br />
With the variables <code>dryRunScript</code>, <code>debugMode</code> and <code>debugMessageSyslogMode</code> script modes can be controlled.
</p>

<h4>Script actions</h4>
<p>The script uses the web interface of the modem to login and issue a reboot command.<br />
With the <i>dryRunScript</i> variable you can control the behavior of the script to just logout instead of rebooting for testing the script.
</p>

<h4>Important notes</h4>
<ul>
  <li>After logging in and while a user session is active the modem blocks any other login attempt. You must successfully log out to be able to login again.</li>
  <li>If you fail to successfully logout, you must either restart (powercycle) the modem or wait for the session timeout (about 5 minutes).</li>
</ul>
