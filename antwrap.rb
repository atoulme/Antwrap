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

module Antwrap
  JFile = java.io.File
  @@log = Logger.new(STDOUT)
  @@log.level = Logger::DEBUG
  @@standard_tasks = Hash[:mkdir => "org.apache.tools.ant.taskdefs.Mkdir",
                      :javac => "org.apache.tools.ant.taskdefs.Javac",
                      :chmod => "org.apache.tools.ant.taskdefs.Chmod",
                      :delete => "org.apache.tools.ant.taskdefs.Delete",
                      :copy => "org.apache.tools.ant.taskdefs.Copy",
                      :move => "org.apache.tools.ant.taskdefs.Move",
                      :jar => "org.apache.tools.ant.taskdefs.Jar",
                      :rmic => "org.apache.tools.ant.taskdefs.Rmic",
                      :cvs => "org.apache.tools.ant.taskdefs.Cvs",
                      :get => "org.apache.tools.ant.taskdefs.Get",
                      :unzip => "org.apache.tools.ant.taskdefs.Expand",
                      :unjar => "org.apache.tools.ant.taskdefs.Expand",
                      :unwar => "org.apache.tools.ant.taskdefs.Expand",
                      :echo => "org.apache.tools.ant.taskdefs.Echo",
                      :javadoc => "org.apache.tools.ant.taskdefs.Javadoc",
                      :zip => "org.apache.tools.ant.taskdefs.Zip",
                      :gzip => "org.apache.tools.ant.taskdefs.GZip",
                      :gunzip => "org.apache.tools.ant.taskdefs.GUnzip",
                      :replace => "org.apache.tools.ant.taskdefs.Replace",
                      :java => "org.apache.tools.ant.taskdefs.Java",
                      :tstamp => "org.apache.tools.ant.taskdefs.Tstamp",
                      :property => "org.apache.tools.ant.taskdefs.Property",
                      :xmlproperty => "org.apache.tools.ant.taskdefs.XmlProperty",
                      :taskdef => "org.apache.tools.ant.taskdefs.Taskdef",
                      :ant => "org.apache.tools.ant.taskdefs.Ant",
                      :exec => "org.apache.tools.ant.taskdefs.ExecTask",
                      :tar => "org.apache.tools.ant.taskdefs.Tar",
                      :untar => "org.apache.tools.ant.taskdefs.Untar",
                      :available => "org.apache.tools.ant.taskdefs.Available",
                      :filter => "org.apache.tools.ant.taskdefs.Filter",
                      :fixcrlf => "org.apache.tools.ant.taskdefs.FixCRLF",
                      :patch => "org.apache.tools.ant.taskdefs.Patch",
                      :style => "org.apache.tools.ant.taskdefs.XSLTProcess",
                      :xslt => "org.apache.tools.ant.taskdefs.XSLTProcess",
                      :touch => "org.apache.tools.ant.taskdefs.Touch",
                      :signjar => "org.apache.tools.ant.taskdefs.SignJar",
                      :genkey => "org.apache.tools.ant.taskdefs.GenerateKey",
                      :antstructure => "org.apache.tools.ant.taskdefs.AntStructure",
                      :execon => "org.apache.tools.ant.taskdefs.ExecuteOn",
                      :antcall => "org.apache.tools.ant.taskdefs.CallTarget",
                      :sql => "org.apache.tools.ant.taskdefs.SQLExec",
                      :mail => "org.apache.tools.ant.taskdefs.email.EmailTask",
                      :fail => "org.apache.tools.ant.taskdefs.Exit",
                      :war => "org.apache.tools.ant.taskdefs.War",
                      :uptodate => "org.apache.tools.ant.taskdefs.UpToDate",
                      :apply => "org.apache.tools.ant.taskdefs.Transform",
                      :record => "org.apache.tools.ant.taskdefs.Recorder",
                      :cvspass => "org.apache.tools.ant.taskdefs.CVSPass",
                      :typedef => "org.apache.tools.ant.taskdefs.Typedef",
                      :sleep => "org.apache.tools.ant.taskdefs.Sleep",
                      :pathconvert => "org.apache.tools.ant.taskdefs.PathConvert",
                      :ear => "org.apache.tools.ant.taskdefs.Ear",
                      :parallel => "org.apache.tools.ant.taskdefs.Parallel",
                      :sequential => "org.apache.tools.ant.taskdefs.Sequential",
                      :condition => "org.apache.tools.ant.taskdefs.ConditionTask",
                      :dependset => "org.apache.tools.ant.taskdefs.DependSet",
                      :bzip2 => "org.apache.tools.ant.taskdefs.BZip2",
                      :bunzip2 => "org.apache.tools.ant.taskdefs.BUnzip2",
                      :checksum => "org.apache.tools.ant.taskdefs.Checksum",
                      :waitfor => "org.apache.tools.ant.taskdefs.WaitFor",
                      :input => "org.apache.tools.ant.taskdefs.Input",
                      :loadfile => "org.apache.tools.ant.taskdefs.LoadFile",
                      :manifest => "org.apache.tools.ant.taskdefs.ManifestTask",
                      :loadproperties => "org.apache.tools.ant.taskdefs.LoadProperties",
                      :basename => "org.apache.tools.ant.taskdefs.Basename",
                      :dirname => "org.apache.tools.ant.taskdefs.Dirname",
                      :cvschangelog => "org.apache.tools.ant.taskdefs.cvslib.ChangeLogTask",
                      :cvsversion => "org.apache.tools.ant.taskdefs.cvslib.CvsVersion",
                      :buildnumber => "org.apache.tools.ant.taskdefs.BuildNumber",
                      :concat => "org.apache.tools.ant.taskdefs.Concat",
                      :cvstagdiff => "org.apache.tools.ant.taskdefs.cvslib.CvsTagDiff",
                      :tempfile => "org.apache.tools.ant.taskdefs.TempFile",
                      :import => "org.apache.tools.ant.taskdefs.ImportTask",
                      :whichresource => "org.apache.tools.ant.taskdefs.WhichResource",
                      :subant => "org.apache.tools.ant.taskdefs.SubAnt",
                      :sync => "org.apache.tools.ant.taskdefs.Sync",
                      :defaultexcludes => "org.apache.tools.ant.taskdefs.DefaultExcludes",
                      :presetdef => "org.apache.tools.ant.taskdefs.PreSetDef",
                      :macrodef => "org.apache.tools.ant.taskdefs.MacroDef",
                      :nice => "org.apache.tools.ant.taskdefs.Nice",
                      :length => "org.apache.tools.ant.taskdefs.Length"]
  
  public
  def method_missing(sym, *args)
    puts "Antwrap.method_missing for #{sym} [#{args}]"
    if(@@standard_tasks.member?(sym))
      ant_task(@@standard_tasks[sym], args[0])    
    else
      super.method_missing(sym, args)
    end
  end
  
  def unzip(attributes)
    attributes[:taskType] = 'unzip'
    attributes[:taskName] = 'unzip'
    ant_task('org.apache.tools.ant.taskdefs.Expand', attributes)    
  end
  
  def jar(attributes)
    attributes[:destFile]  =  java.io.File.new(attributes[:destfile])
    attributes.delete_if{|key, value| key.to_s().eql?("destfile")}
    ant_task("org.apache.tools.ant.taskdefs.Jar", attributes)
  end  

  def javac(attributes)
    @@log.info("javac")
    attributes[:srcdir]  = org.apache.tools.ant.types.Path.new(AntProject.create, attributes[:srcdir])
    attributes[:classpath]  = org.apache.tools.ant.types.Path.new(AntProject.create, attributes[:classpath])
    ant_task("org.apache.tools.ant.taskdefs.Javac", attributes)
  end  
  
  def ant_task(taskname, attributes)
    @@log.info("ant_task")
    taskdef = make_instance(taskname)
    taskdef.send('setProject', AntProject.create)
    attributes.each do |key, value| 
      method = make_set_method(key)
      begin
        taskdef.send(method, introspect(value)) 
      rescue  StandardError => error
        @@log.error("Error occured attempting to invoke method: '#{method}' with value[#{value}]")
        @@log.error("#{error}")
      end
    end
    taskdef
  end
  
  def make_set_method(name)
    str = name.to_s
    return 'set' + str[0,1].capitalize + str[1, str.length - 1]
  end
  
  def introspect(value)
    case
      when value.instance_of?(TrueClass) || value.instance_of?(FalseClass)
        return java_to_primitive(value)
      when value.instance_of?(String) && File.exists?(value)
        return JFile.new(value)  
      when value.instance_of?(String) && (value.eql?('true') || value.eql?('on') || value.eql?('yes'))
        return java_to_primitive(true)
      when value.instance_of?(String) && (value.eql?('false') || value.eql?('off') || value.eql?('no'))
        return java_to_primitive(false)
      else
        return value
    end
  end

  private
  def make_instance(clazz)
    clazz = java.lang.Class.forName(clazz)
    return clazz.newInstance
  end
  
end