== AutomateIt

<em>AutomateIt is an open-source tool for automating the setup and maintenance of Unix systems.</em>

Information about AutomateIt is best read in the following order:
1. http://AutomateIt.org -- website explaining what it is and why it's useful
2. Screenshots[http://AutomateIt.org/screenshots] -- quick tour of sample AutomateIt code
3. TUTORIAL.txt[link:files/TUTORIAL_txt.html] -- the "Get Started" hands-on tutorial
4. TESTING.txt[link:files/TESTING_txt.html] -- instructions on running the AutomateIt self-test
5. Links on the left provide technical documentation for specific classes and methods

=== Quick links

Unix commands, run with <tt>--help</tt> for details:
* +automateit+ or +ai+ -- Run a recipe or create a project.
* +aitag+ -- Query project's tags.
* +aifield+ -- Query project's fields.

Execution:
* AutomateIt::Interpreter -- Runs AutomateIt commands.
* AutomateIt::Project -- Collection of related recipes, tags, fields and custom plugins.

Plugins:
* AutomateIt::AccountManager -- Manipulates users and groups.
* AutomateIt::AddressManager -- Manipulates host's network addresses.
* AutomateIt::EditManager -- Edits files and strings.
* AutomateIt::FieldManager -- Queries configuration variables.
* AutomateIt::PackageManager -- Manipulates software packages.
* AutomateIt::PlatformManager -- Queries platform, such as its OS version.
* AutomateIt::ServiceManager -- Manipulates services, such as Unix daemons.
* AutomateIt::ShellManager -- Manipulates files and executes Unix commands.
* AutomateIt::TagManager -- Groups hosts by role and queries membership.
* AutomateIt::TemplateManager -- Renders templates to files.

Useful drivers:
* AutomateIt::EditManager::Basic::EditSession -- Commands for editing files.
* AutomateIt::TemplateManager::ERB -- Commands for rendering files.

=== Legal

Copyright (C) 2007 Igal Koshevoy (igal@pragmaticraft.com)

AutomateIt is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see: http://www.gnu.org/licenses/
