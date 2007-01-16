require 'java'
require 'fileutils'
require 'logger'

@@log = Logger.new(STDOUT)
@@log.level = Logger::INFO
  
class AntTask
  private
  @@task_stack=Array.new
  attr_reader :unknown_element, :project, :taskname
  
  public  
  def initialize(taskname, project, attributes, proc)
    @taskname = taskname
    @project = project
    @unknown_element = Java::org.apache.tools.ant.UnknownElement.new(taskname)
    @unknown_element.setProject(project);
    @unknown_element.setNamespace('');
    @unknown_element.setQName(taskname);
    @unknown_element.setTaskType(taskname);
    @unknown_element.setTaskName(taskname);
    
    wrapper = Java::org.apache.tools.ant.RuntimeConfigurable.new(@unknown_element, @unknown_element.getTaskName());
    if attributes
      attributes.each do |key, value| 
        wrapper.setAttribute(key.to_s, value)
      end
    end
    
    if proc
      @@log.debug("task_stack.push #{taskname} >> #{@@task_stack}") 
      @@task_stack.push self

      singleton_class = class << proc; self; end
      singleton_class.module_eval{
        def method_missing(m, *a, &proc)
          @@task_stack.last().send(m, *a, &proc)
        end
      }
      proc.instance_eval &proc
      @@task_stack.pop 
    end
  end

  def method_missing(sym, *args)
    @@log.debug("AntTask.method_missing sym[#{sym.to_s}]")
    begin
      proc = block_given? ? Proc.new : nil 
      self.add(AntTask.new(sym.to_s, project, args[0], proc))
    rescue StandardError
      @@log.error("AntTask.method_missing error:" + $!)
    end
  end  
  
  def add(child)
    @@log.debug("adding child[#{child.unknown_element().getTaskName()}] to [#{@unknown_element.getTaskName()}]")
    @unknown_element.addChild(child.unknown_element())
    @unknown_element.getRuntimeConfigurableWrapper().addChild(child.unknown_element().getRuntimeConfigurableWrapper())
  end
  
  def execute
    puts "execute #{taskname}"
    begin
      @unknown_element.maybeConfigure
    rescue
      @@log.error("failed maybeConfigure")
    end
    @unknown_element.execute
  end
end

class Ant
    
    attr :project, false
    attr :declarative, true
    
    def initialize(declarative=true)
      self.declarative=(declarative)      
      @project= Java::org.apache.tools.ant.Project.new
      @project.init
      default_logger = Java::org.apache.tools.ant.DefaultLogger.new
      default_logger.setMessageOutputLevel(2);
      default_logger.setOutputPrintStream(java.lang.System.out);
      default_logger.setErrorPrintStream(java.lang.System.err);
      default_logger.setEmacsMode(false);
      @project.addBuildListener(default_logger)
    end
  
  def create_task(taskname, attributes, proc)
    task = AntTask.new(taskname, project(), attributes, proc)
    task.execute if declarative()
    @@tasks.push(attributes[:name]) if taskname == 'macrodef'
    task
  end
  
  def method_missing(sym, *args)
    if(@@tasks.include?(sym.to_s) || @@types.include?(sym.to_s))
      begin
        @@log.info("Ant.method_missing sym[#{sym.to_s}]")
        proc = block_given? ? Proc.new : nil 
        return create_task(sym.to_s, args[0], proc)
      rescue
        @@log.error("Error instantiating task[#{sym.to_s}]")
      end
    else
        @@log.error("Not an Ant Task[#{sym.to_s}]")
    end
  end
  
  #overridden. 'java' conflicts wth the jruby module.
  def jvm(attributes)
    proc = block_given? ? Proc.new : nil 
    create_task('java', attributes, proc)
  end  
  
  #overridden. 'mkdir' conflicts wth the rake library.
  def mkdir(attributes)
    proc = block_given? ? Proc.new : nil 
    create_task('mkdir', attributes, proc)
  end  
  
  #overridden. 'copy' conflicts wth the rake library.
  def copy(attributes)
    proc = block_given? ? Proc.new : nil 
    create_task('copy', attributes, proc)
  end  
  
  def properties(props=Hash.new())
    props.each {|key, value| project().setNewProperty(key.to_s, value) }
  end
  
  @@tasks = [
  # standard ant tasks
      'mkdir', 'javac',   'chmod', 'delete', 'copy', 'move', 'jar', 'rmic', 'cvs', 'get', 'unzip', 
      'unjar', 'unwar', 'echo', 'javadoc', 'zip', 'gzip', 'gunzip', 'replace', 'java', 'tstamp', 'property', 
      'xmlproperty', 'taskdef', 'ant', 'exec', 'tar', 'untar', 'available', 'filter', 'fixcrlf', 'patch', 
      'style', 'xslt', 'touch', 'signjar', 'genkey', 'antstructure', 'execon', 'antcall', 'sql', 'mail', 
      'fail', 'war', 'uptodate', 'apply', 'record', 'cvspass', 'typedef', 'sleep', 'pathconvert', 'ear', 
      'parallel', 'sequential', 'condition', 'dependset', 'bzip2', 'bunzip2', 'checksum', 'waitfor', 'input', 
      'loadfile', 'manifest', 'loadproperties', 'basename', 'dirname', 'cvschangelog', 'cvsversion', 'buildnumber', 
      'concat', 'cvstagdiff', 'tempfile', 'import', 'whichresource', 'subant', 'sync', 'defaultexcludes', 'presetdef', 
      'macrodef', 'nice', 'length', 
  # optional tasks
      'image', 'script', 'netrexxc', 'renameext', 'ejbc', 'ddcreator', 'wlrun', 'wlstop', 'vssadd', 'vsscheckin', 'vsscheckout', 
      'vsscp', 'vsscreate', 'vssget', 'vsshistory', 'vsslabel', 'ejbjar', 'mparse', 'mmetrics', 'maudit', 'junit', 'cab', 
      'ftp', 'icontract', 'javacc', 'jjdoc', 'jjtree', 'stcheckout', 'stcheckin', 'stlabel', 'stlist', 'wljspc', 'jlink', 
      'native2ascii', 'propertyfile', 'depend', 'antlr', 'vajload', 'vajexport', 'vajimport', 'telnet', 'csc', 'ilasm', 
      'WsdlToDotnet', 'wsdltodotnet', 'importtypelib', 'stylebook', 'test', 'pvcs', 'p4change', 'p4delete', 'p4label', 'p4labelsync', 
      'p4have', 'p4sync', 'p4edit', 'p4integrate', 'p4resolve', 'p4submit', 'p4counter', 'p4revert', 'p4reopen', 'p4fstat', 'javah', 
      'ccupdate', 'cccheckout', 'cccheckin', 'ccuncheckout', 'ccmklbtype', 'ccmklabel', 'ccrmtype', 'cclock', 'ccunlock', 'ccmkbl', 
      'ccmkattr', 'ccmkelem', 'ccmkdir', 'sound', 'junitreport', 'blgenclient', 'rpm', 'xmlvalidate', 'iplanet-ejbc', 'jdepend', 
      'mimemail', 'ccmcheckin', 'ccmcheckout', 'ccmcheckintask', 'ccmreconfigure', 'ccmcreatetask', 'jpcoverage', 'jpcovmerge', 
      'jpcovreport', 'p4add', 'jspc', 'replaceregexp', 'translate', 'sosget', 'soscheckin','soscheckout','soslabel', 'echoproperties', 
      'splash', 'serverdeploy', 'jarlib-display', 'jarlib-manifest', 'jarlib-available', 'jarlib-resolve', 'setproxy', 'vbc', 'symlink', 
      'chgrp', 'chown', 'attrib', 'scp', 'sshexec', 'jsharpc', 'rexec', 'scriptdef', 'ildasm', 
  # deprecated ant tasks (kept for back compatibility)
      'starteam', 'javadoc2', 'copydir', 'copyfile', 'deltree', 'rename'] 
  
  @@types = [ 'classfileset', 'description', 'dirset', 'filelist', 'fileset', 'filterchain', 'filterreader', 'filterset', 'mapper', 'redirector', 
      'identitymapper', 'flattenmapper', 'globmapper', 'mergemapper', 'regexpmapper', 'packagemapper', 'unpackagemapper', 'compositemapper', 
      'chainedmapper', 'filtermapper', 'path', 'patternset', 'regexp', 'substitution', 'xmlcatalog', 'extensionSet', 'extension', 'libfileset', 
      'selector', 'zipfileset', 'scriptfilter', 'propertyset', 'assertions', 'concatfilter', 'isfileselected' ]
  
end