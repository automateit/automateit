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
* <b>Easy-to-learn</b> recipe code is instantly familiar to any UNIX user
* <b>Productive</b>, creates sophisticated, high-quality system configurations quickly
* <b>Powerful</b> language and extensible plugin architecture meet your unique needs
* <b>Open source</b>, secure, documented, and comes with a complete self-test suite

Faster, more efficient system administration will help you run circles around competitors, impress your boss, and let you sleep better at night.

Try AutomateIt today!

=== How does AutomateIt compare to other tools?

AutomateIt vs. Cfengine and Puppet:

- <b>Easier to setup</b>: Creates a project with one command. No need to dedicate your system to it or setup daemons, client-server connections, certificates, or arcane file structures.
- <b>Easier to learn</b>: Any UNIX user can read recipes and quickly learn to write recipes using familiar programming conventions. No need to learn a completely new programming paradigm or language deliberately designed to be less usable than BASIC.
- <b>Faster development</b>: Get more done quicker with less code. Develop and preview recipes in an interactive shell. No gobs of boilerplate or need to re-execute your entire system configuration.
- <b>More powerful</b>: Work with a full-featured programming language. No need to live within the painful constraints of a limited, single-purpose language.
- <b>More accessible</b>: Easily access UNIX from inside tool -- or have UNIX programs access the tool from inside themselves. No need to live with a blackbox you can't get data into or out of.
- <b>Fully extensible</b>: Add functionality and platform-specific drivers, or change existing behavior by simply dropping files into your project's "lib" directory. No need to fork code or write elaborate hacks to execute external commands to implement basic features and logic the tool can't handle itself.
- <b>Totally testable</b>: Includes a self-test suite so you can check the tool's sanity on your platforms. No more catastrophes because your tool vendor can't be bothered to check that their tool works. 

Mark Burgess' Cfengine[http://cfengine.org] set the gold standard for system configuration management tools. Luke Kanies' Puppet[http://reductivelabs.com/trac/puppet] provides some incremental improvements to Cfengine, along with some peculiar constraints. Mark and Luke have done a fantastic service to the community by making automated system administration a reality and preaching its gospel. However, the way their ideals are implemented leaves much to be desired. These issues can't be addressed by bugfixes or patches because there are fundamental flaws in their products' designs.

Cfengine and Puppet seem to have been written from the assumption that their authors knew _exactly_ how your systems should work and how you'll administer them. If you didn't fit this overly-simplistic model, you suffered. These tightly-constrained languages severely limit what you can do and actively prevent you from doing anything else. Once your system configuration reaches even moderate complexity, it becomes a mire of twisty dependency logic few can follow and requires a huge pile of external programs to awkwardly implement basic features the underlying tool lacks. Do you really want to use a limited and functionally-closed tool that forces you to write awkward code and build hacks outside the tool to deal with its inadequacies?

AutomateIt addresses these issues by solving the problem in a radically different way. It implements the full set of Cfengine and Puppet's features so you can solve the problems you already have, but more easily. It uses a conventional programming approach that's familiar to anyone that's used a UNIX shell. It packs a full-featured programming language that lets you choose how to administer your systems in the most effective way. You can choose to use AutomateIt's built-in features, leverage its infrastructure to write your own, or effortlessly interact with external programs. The tool's plugin architecture lets you extend its features and easily make it run on platforms that weren't supported out-of-the-box. AutomateIt is general-purpose and open, letting you quickly and easily write clear, succinct system configuration.

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

=== Legal

Author:: Igal Koshevoy (igal@pragmaticraft.com)
Copyright:: Copyright (c) 2007 Igal Koshevoy
License:: Distributed under the same terms as Ruby (http://www.ruby-lang.org/en/LICENSE.txt)
