= AutomateIt

<em>AutomateIt is an open-source tool for automating the setup and maintenance of UNIX systems.</em>

=== Getting started

1. Install[link:files/INSTALL_txt.html] it.
2. Use[link:files/USAGE_txt.html] it.
3. Profit!

=== AutomateIt: It's System Administration 2.0

AutomateIt is an open-source tool for automating the setup and maintenance of UNIX systems.

Benefits anyone needing high-quality applications and IT services:
* Application development teams
* Online services providers
* Business-critical application support organizations
* System administrators and integrators
* Change management, migration and disaster recovery projects

Helps your technology-dependant organization:
* Turns change into a competitive advantage
* Speeds product development and boosts quality
* Improves business agility
* Reduces downtime,  errors and surprises
* Simplifies updates, migrations and recovery

Empowers your engineering and operations staff:
* <b>Codifies knowledge</b> into reusable, previewable and maintainable recipes
* <b>Easy-to-learn</b> recipe code is instantly familiar to anyone that's written a shell script
* <b>Productive</b>, creates sophisticated, high-quality system configurations quickly
* <b>Powerful</b> language and extensible plugin architecture meet your unique needs
* <b>Open source</b>, secure, documented, and comes with a complete self-test suite

Faster, more efficient system administration will help you run circles around competitors, impress your boss, and let you sleep better at night.

Try AutomateIt today!

=== How does AutomateIt compare to other tools?

AutomateIt vs. Cfengine and Puppet:

- <b>Easier to setup</b>: Creates a project with one command. No need to setup daemons, client-server connections, certificates, or arcane file structures.
- <b>Easier to learn</b>: Any UNIX user can read recipes and quickly learn to write recipes using familiar programming conventions. No need to learn a totally new paradigm or work with a language that's deliberately designed not to be used for programming.
- <b>Faster development</b>: Get more done quicker with less code. Develop and preview recipes in an interactive shell. No gobs of boilerplate, dependency graphs, or need to re-execute your entire system configuration.
- <b>More powerful</b>: Work with a full-featured programming language. No need to live within the painful constraints of a limited, single-purpose language.
- <b>More accessible</b>: Easily access UNIX from inside tool -- or have UNIX programs access the tool from inside themselves. No need to live with a blackbox you can't get data into or out of.
- <b>Fully extensible</b>: Add functionality and platform-specific drivers, or change existing behavior by simply dropping files into your project's "lib" directory. No need to fork code or write elaborate hacks to execute external commands to implement basic features and logic the tool can't handle itself.
- <b>Totally testable</b>: Includes a self-test suite so you can check the tool's sanity on your platforms. No more catastrophes because your tool vendor can't be bothered to check that their tool works.
- <b>Beta-quality</b>: AutomateIt is a very new product and, despite the comprehensive test suite, beta users must accept that there will be teething pains, a need for frequent updates and limited driver support. These issues will be resolved with time.

Mark Burgess' Cfengine[http://cfengine.org] set the gold standard for system configuration management tools. Luke Kanies' Puppet[http://reductivelabs.com/trac/puppet] provides some incremental improvements to Cfengine, along with some peculiar constraints. Mark and Luke have done a fantastic service to the community by making automated system administration a reality and preaching its gospel. However, the way their ideals are implemented leaves something to be desired.

Cfengine and Puppet are designed as elegant, minimalistic, special-purpose declarative languages. You use them to describe the expected state of your system using targets and dependency graphs, and the tool figures out what to do to create this state. Unfortunately, as your recipes grow to even moderate complexity, the dependency graphs become so difficult to follow that you'll have a hard time following and the tool might not even be able to run commands in the right order. You'll also quickly find that the minimalistic nature of these tools means you can't do many things you need and find yourself writing elaborate hacks to get around limitations. Many Cfengine configurations rely on custom-crafted code-generators and external programs that implement much of the logic that the tool can't. The irony is that these tools were supposed to be simple, elegant and easy for anyone to understand, but in the real world, even moderately complex tasks are so convoluted that only gurus can effectively accomplish them.

AutomateIt approaches system configuration management from an entirely different angle. It includes the basic features of Cfengine and Puppet, plus many more, but in the form of a library for a conventional programming language, utility programs, and an interactive shell. This dramatically boosts AutomateIt's power and clarity. Its code and programming approach will be familiar to anyone that's written a shell script. Commands are executed in a predictable order and you can use standard language features like conditionals to decide which code to run. AutomateIt lets you choose how to best administer your systems, rather than forcing a problematic model on you. You can choose to use its built-in features, leverage its infrastructure to write your own custom code, or effortlessly interact with external programs. The tool's plugin architecture lets you extend its features and easily make it run on platforms that weren't supported out-of-the-box. You can drop your new features and plugins into your project's "lib" directory and they'll be automatically loaded for you, which saves you from having to maintain a fork of the tools' code. AutomateIt's approach lets you quickly and easily write clear, succinct system configurations without needing to make compromises.

=== Why should I trust AutomateIt?

Unlike most configuration management products, AutomateIt is built to solve real-world problems. Its design is the result of over a decade of hard-won lessons administering business-critical applications at geographically-distributed data-centers with hundreds of servers in multiple clusters, dozens of OSes and countless configuration permutations.

See if AutomateIt is right for you:
- Read the documentation
- Review the code, it's open source
- Try out the example project on a virtual machine to see it in action
- Run the self-test to validate it against your platform of choice
- Implement a small project to see what it can do for you

=== FIXME

=== What is AutomateIt and why should you care?

Manual system administration processes are expensive and put your business at risk. AutomateIt is an open-source tool for automating the setup and maintenance of UNIX systems. It helps your company speed up development, deliver high-quality application and network services, reduce errors and downtime, and can rebuild entire clusters with a single command.

AutomateIt lets you write recipes that encapsulate your system setup and maintenance tasks into portable, repeatable and maintainable recipes. These recipes are so easy to understand that any UNIX user will be able to read them without additional training. Yet despite this easy of use, AutomateIt is the most powerful and feature-packed tool available. You can quickly adapt it to your unique needs by writing plugins and drivers with the embedded, full-featured programming language.

Unlike most competing products, AutomateIt is built to solve real-world problems. Its design is the result of over a decade of hard-won lessons administering business-critical applications at geographically-distributed data-centers with hundreds of servers in multiple clusters, dozens of OSes and countless configuration permutations. AutomateIt gives you all the features of industry-standard configuration management products like cfengine, but is more powerful, flexible and easier-to-use.

Check out AutomateIt today!

=== Support

Professional services for AutomateIt are available through Pragmaticraft[http://Pragmaticraft.com].

Community support and release notifications are available at the http://AutomateIt.org website.

=== Beta

AutomateIt is beta-quality software. It's feature-complete, exceeds the capabilities of other major products, and ensures its quality with a test suite that provides nearly-complete code coverage. However, this is a young, product and early users should have a high-degree of technical understanding, be willing to accept rough spots and work through problems. Driver support for some operating systems is limited, although users are encouraged to write and submit drivers or provide access to their platforms so the product's authors can write these. Users are expected to sign up at the http://AutomateIt.org website so they can be notified of releases and apply these updates regularly to take advantage of bugfixes and new features.

The 1.0 release of AutomateIt will provide 100% code coverage and complete drivers for:
- Ubuntu
- Debian
- Fedora Core
- CentOS
- Red Hat
- Gentoo
- FreeBSD
- OpenBSD
- Solaris
- Darwin

=== Driver support issues

Most of AutomateIt's features will work on any system that can run Ruby. Ubuntu and Fedora Core are currently the only fully-supported and tested platforms, but others will be included with time. You can see what drivers are supported on your platform by running the integration test suite and it'll complain when it can't test a driver.

If no driver is available for your platform or tool, you can probably write one in 30 minutes, it's really that easy. Just find an included driver that's similar to what you need, look at its code, and create your own derivative. You'll want to put your new driver code into an file that ends with ".rb" into your project's "lib" directory so it'll be loaded automatically when you run the Interpreter. Please contribute your drivers back so others can benefit. If you don't want to write your own driver, please provide access to a system so AutomateIt's author can write it for you.

If you don't want to write drivers, there are workarounds. For example, if you need to tag machines by operating system and release versions but AutomateIt doesn't have a driver to get this information on your platform, just edit the tags.yml file manually to create the appropriate tags. Or if you need to install packages using an unsupported package manager, you can just use the +sh+ command to execute the system-level tool yourself. This isn't pretty, but it'll get the job done.

=== Future plugins

Plugins that might be implemented in the future:
* ScheduleManager -- Manipulates regular command execution schedules, e.g. cron.
* TransferManager -- Transfers files from some source, e.g. rsync, sftp, http.
* SourceManager -- Manipulates source control systems, e.g. svn, cvs, hg.

=== Legal

Author:: Igal Koshevoy (igal@pragmaticraft.com)
Copyright:: Copyright (c) 2007 Igal Koshevoy
License:: Distributed under the same terms as Ruby (http://www.ruby-lang.org/en/LICENSE.txt)
