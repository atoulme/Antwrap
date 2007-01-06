require 'java'
require 'fileutils'
require 'logger'
include Java

class AntProject
  private_class_method :new
  @@project = nil
  def AntProject.create
    if @@project == nil
      @@project= org.apache.tools.ant.Project.new
      @@project.init
    end
    return @@project
  end
end

class AntTask < org.apache.tools.ant.UnknownElement
  
  def add(child)
    getRuntimeConfigurableWrapper().addChild(child.getRuntimeConfigurableWrapper())
    addChild(child)
  end
  
  def execute
    maybeConfigure
    super
  end
  
end

class Ant
  private
  @@log = Logger.new(STDOUT)
  @@log.level = Logger::DEBUG
  @@standard_tasks = Hash[:mkdir => 'org.apache.tools.ant.taskdefs.Mkdir',
  :javac => 'org.apache.tools.ant.taskdefs.Javac',
  :chmod => 'org.apache.tools.ant.taskdefs.Chmod',
  :delete => 'org.apache.tools.ant.taskdefs.Delete',
  :copy => 'org.apache.tools.ant.taskdefs.Copy',
  :move => 'org.apache.tools.ant.taskdefs.Move',
  :jar => 'org.apache.tools.ant.taskdefs.Jar',
  :rmic => 'org.apache.tools.ant.taskdefs.Rmic',
  :cvs => 'org.apache.tools.ant.taskdefs.Cvs',
  :get => 'org.apache.tools.ant.taskdefs.Get',
  :unzip => 'org.apache.tools.ant.taskdefs.Expand',
  :unjar => 'org.apache.tools.ant.taskdefs.Expand',
  :unwar => 'org.apache.tools.ant.taskdefs.Expand',
  :echo => 'org.apache.tools.ant.taskdefs.Echo',
  :javadoc => 'org.apache.tools.ant.taskdefs.Javadoc',
  :zip => 'org.apache.tools.ant.taskdefs.Zip',
  :gzip => 'org.apache.tools.ant.taskdefs.GZip',
  :gunzip => 'org.apache.tools.ant.taskdefs.GUnzip',
  :replace => 'org.apache.tools.ant.taskdefs.Replace',
  :java => 'org.apache.tools.ant.taskdefs.Java',
  :tstamp => 'org.apache.tools.ant.taskdefs.Tstamp',
  :property => 'org.apache.tools.ant.taskdefs.Property',
  :xmlproperty => 'org.apache.tools.ant.taskdefs.XmlProperty',
  :taskdef => 'org.apache.tools.ant.taskdefs.Taskdef',
  :ant => 'org.apache.tools.ant.taskdefs.Ant',
  :exec => 'org.apache.tools.ant.taskdefs.ExecTask',
  :tar => 'org.apache.tools.ant.taskdefs.Tar',
  :untar => 'org.apache.tools.ant.taskdefs.Untar',
  :available => 'org.apache.tools.ant.taskdefs.Available',
  :filter => 'org.apache.tools.ant.taskdefs.Filter',
  :fixcrlf => 'org.apache.tools.ant.taskdefs.FixCRLF',
  :patch => 'org.apache.tools.ant.taskdefs.Patch',
  :style => 'org.apache.tools.ant.taskdefs.XSLTProcess',
  :xslt => 'org.apache.tools.ant.taskdefs.XSLTProcess',
  :touch => 'org.apache.tools.ant.taskdefs.Touch',
  :signjar => 'org.apache.tools.ant.taskdefs.SignJar',
  :genkey => 'org.apache.tools.ant.taskdefs.GenerateKey',
  :antstructure => 'org.apache.tools.ant.taskdefs.AntStructure',
  :execon => 'org.apache.tools.ant.taskdefs.ExecuteOn',
  :antcall => 'org.apache.tools.ant.taskdefs.CallTarget',
  :sql => 'org.apache.tools.ant.taskdefs.SQLExec',
  :mail => 'org.apache.tools.ant.taskdefs.email.EmailTask',
  :fail => 'org.apache.tools.ant.taskdefs.Exit',
  :war => 'org.apache.tools.ant.taskdefs.War',
  :uptodate => 'org.apache.tools.ant.taskdefs.UpToDate',
  :apply => 'org.apache.tools.ant.taskdefs.Transform',
  :record => 'org.apache.tools.ant.taskdefs.Recorder',
  :cvspass => 'org.apache.tools.ant.taskdefs.CVSPass',
  :typedef => 'org.apache.tools.ant.taskdefs.Typedef',
  :sleep => 'org.apache.tools.ant.taskdefs.Sleep',
  :pathconvert => 'org.apache.tools.ant.taskdefs.PathConvert',
  :ear => 'org.apache.tools.ant.taskdefs.Ear',
  :parallel => 'org.apache.tools.ant.taskdefs.Parallel',
  :sequential => 'org.apache.tools.ant.taskdefs.Sequential',
  :condition => 'org.apache.tools.ant.taskdefs.ConditionTask',
  :dependset => 'org.apache.tools.ant.taskdefs.DependSet',
  :bzip2 => 'org.apache.tools.ant.taskdefs.BZip2',
  :bunzip2 => 'org.apache.tools.ant.taskdefs.BUnzip2',
  :checksum => 'org.apache.tools.ant.taskdefs.Checksum',
  :waitfor => 'org.apache.tools.ant.taskdefs.WaitFor',
  :input => 'org.apache.tools.ant.taskdefs.Input',
  :loadfile => 'org.apache.tools.ant.taskdefs.LoadFile',
  :manifest => 'org.apache.tools.ant.taskdefs.ManifestTask',
  :loadproperties => 'org.apache.tools.ant.taskdefs.LoadProperties',
  :basename => 'org.apache.tools.ant.taskdefs.Basename',
  :dirname => 'org.apache.tools.ant.taskdefs.Dirname',
  :cvschangelog => 'org.apache.tools.ant.taskdefs.cvslib.ChangeLogTask',
  :cvsversion => 'org.apache.tools.ant.taskdefs.cvslib.CvsVersion',
  :buildnumber => 'org.apache.tools.ant.taskdefs.BuildNumber',
  :concat => 'org.apache.tools.ant.taskdefs.Concat',
  :cvstagdiff => 'org.apache.tools.ant.taskdefs.cvslib.CvsTagDiff',
  :tempfile => 'org.apache.tools.ant.taskdefs.TempFile',
  :import => 'org.apache.tools.ant.taskdefs.ImportTask',
  :whichresource => 'org.apache.tools.ant.taskdefs.WhichResource',
  :subant => 'org.apache.tools.ant.taskdefs.SubAnt',
  :sync => 'org.apache.tools.ant.taskdefs.Sync',
  :defaultexcludes => 'org.apache.tools.ant.taskdefs.DefaultExcludes',
  :presetdef => 'org.apache.tools.ant.taskdefs.PreSetDef',
  :macrodef => 'org.apache.tools.ant.taskdefs.MacroDef',
  :nice => 'org.apache.tools.ant.taskdefs.Nice',
  :length => 'org.apache.tools.ant.taskdefs.Length']
  
  @project = nil
    
  public
  def get_project()
    if @project == nil
      @project= org.apache.tools.ant.Project.new
      @project.init
    end
    return @project
  end
  
  def method_missing(sym, *args)
    #    if(@@standard_tasks.member?(sym))
    @@log.debug("method_missing sym[#{sym.to_s}]")
    create_task(sym.to_s, args[0])    
    #    else
    #      super.method_missing(sym, args)
    #    end
  end
  
  def jvm(attributes)
    @@log.info('jvm')
    create_task('java', attributes)
  end  

  def mkdir(attributes)
    @@log.info('jvm')
    create_task('mkdir', attributes)
  end  
  
  def create_task(taskname, attributes)
    @@log.debug('create_task')
    task = AntTask.new(taskname);
    task.setProject(get_project());
    task.setNamespace('');
    task.setQName(taskname);
    task.setTaskType(taskname);
    task.setTaskName(taskname);
    
    wrapper = org.apache.tools.ant.RuntimeConfigurable.new(task, task.getTaskName());
    attributes.each do |key, value| 
      wrapper.setAttribute(key.to_s, value)
    end
    return task
  end
  
end