
import re
from paramiko import SSHClient, client
from multiprocessing.dummy import Pool

class SROSResources:

  def __init__(self):
    self.memTotal = 0
    self.memInUse = 0
    self.memAvailable = 0
    self.CPUUsage = 0.0


  def TestTrue(self):
    return True

  def Get_CPU_Usage(self, output):
    result = 99999
    lines = output.split('\n', 4)
    #line_total = lines[0].strip()
    #line_idle = lines[1].strip() 
    line_usage = lines[2].strip()
    #line_busiest = lines[3].strip()
    # print(line_total)
    # print(line_idle)
    # print(line_usage)
    # print(line_busiest)
    m = re.match( r'(.*)Usage(.*) ([0-9,.]+)%', line_usage, flags=re.MULTILINE)
    if m:
      result = float(m.group(3))
      self.CPUUsage = result
    return result


  def ParseMemoryOutput(self, output):
    lines = output.split('\n', 3)
    line_total = lines[0].strip()
    line_inuse = lines[1].strip()
    line_available = lines[2].strip()
    total = self.getNumber(line_total)
    inuse = self.getNumber(line_inuse)
    free = self.getNumber(line_available)
    return total,inuse,free

  def Save_Current_Memory_Status(self, output):
    total,inUse,free= self.ParseMemoryOutput(output)
    self.memTotal = total
    self.memInUse = inUse
    self.memAvailable = free
    print("Total: {0}   In Use: {1}   Available: {2}".format(total, inUse, free))

  def Get_Running_Memory(self, output):
    total,inUse,free = self.ParseMemoryOutput(output)
    print("Total         Before: {:>12}     After: {:>12}     Difference: {:>12}".format(self.memTotal, total, total - self.memTotal))
    print("In Use        Before: {:>12}     After: {:>12}     Difference: {:>12}".format(self.memInUse, inUse, inUse - self.memInUse))
    print("Available     Before: {:>12}     After: {:>12}     Difference: {:>12}".format(self.memAvailable, free, free - self.memAvailable))

  def getNumber(self, line):
    result = 0
    pattern = r'(.*) ([0-9,]+) bytes'
    m = re.match(pattern, line.replace(',',''), flags=0)
    if m:
      result = int(m.group(2))
    return result


  # This keyword parses a table with 4 columns: title(string), total(int), allocated(int), free(int)
  # separated by space or bar.
  #
  # After getting the values, it will display a fifth column specifying PASS / FAIL / N/A on the 
  # condition that alloc/total ratio exceeds given treshold or not. (or not applicable: if total is zero)
  #
  # The optional failOnTreshholdExceed parameter, if set to True, will fail the relevant robot test
  # if a single line fails, otherwise, line fails will not fail entire robot test (this is default case).

  def Parse_Table_With_Four_Columns(self, output, treshold, failOnTreshholdExceed = False):
    ftreshold = float(treshold)
    pattern = r'([ ]+)(.*)([ ]{1,})([+-|])([ ]+)([0-9]+)([ |]+)([0-9]+)([ |]+)([0-9]+)'
    matches = re.findall(pattern, output, flags=re.MULTILINE)
    fails = 0
    for item in matches:
      if len(item) > 9:
        title = item[1].strip()
        total = int(item[5].strip())
        allocated = int(item[7].strip())
        free = int(item[9].strip())
        if total == 0:
          result = "N/A"
        else:
          if (float(allocated) / float(total)) > ftreshold:
            fails += 1
            result = "FAIL <<<"
          else:
            result = "PASS"
        print("{:40}    total:{:>12}   allocated:{:>12}  free:{:>12}    {:8}".format(title, total, allocated, free, result))
    if failOnTreshholdExceed and (fails > 0):
      raise Exception("EXCEEDED TRESHOLD: {:1}   (%{:2.4})".format(title, float(allocated)/float(total)*100 ))



  def Start_Async_Show(self, host, user, passwd):
    ssh = SSHClient()
    ssh.load_system_host_keys()
    ssh.set_missing_host_key_policy(client.AutoAddPolicy())
    ssh.connect(host, port=22, username=user, password=passwd, timeout=30)
    channel = ssh.invoke_shell()
    channel.exec_command("show router bgp routes | match Routes")
    ssh.close()



  def Start_Show_BGP_Routes(self, host, user, passwd):
    pool = Pool(processes=1)
    pool.apply_async(self.Start_Async_Show,args=[host, user, passwd])


