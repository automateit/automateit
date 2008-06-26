== AutomateIt

<em>AutomateIt is an open source tool for automating the setup and maintenance of servers, applications and their dependencies.</em>

1. http://AutomateIt.org -- website explaining what it is and why it's useful
2. Screenshots[http://AutomateIt.org/screenshots] -- quick tour of sample AutomateIt code
3. TUTORIAL.txt[link:files/TUTORIAL_txt.html] -- hands-on tutorial

=== Frequently-used commands

Execute these from a terminal, use <tt>--help</tt> option for help:
* +automateit+ or +ai+ -- Run a recipe or create a project.
* +aitag+ -- Query project's tags.
* +aifield+ -- Query project's fields.

=== Frequently-used classes

* AutomateIt::Interpreter -- Runs AutomateIt commands.
* AutomateIt::Project -- Collection of related recipes, tags, fields and custom plugins.
* AutomateIt::AccountManager -- Manipulates users and groups.
* AutomateIt::AddressManager -- Manipulates host's network addresses.
* AutomateIt::DownloadManager -- Downloads files.
* AutomateIt::EditManager::EditSession -- Commands for editing files.
* AutomateIt::FieldManager -- Queries configuration variables.
* AutomateIt::PackageManager -- Manipulates software packages.
* AutomateIt::PlatformManager -- Queries platform, such as its OS version.
* AutomateIt::ServiceManager -- Manipulates services, such as Unix daemons.
* AutomateIt::ShellManager -- Manipulates files and executes Unix commands.
* AutomateIt::TagManager -- Groups hosts by role and queries membership.
* AutomateIt::TemplateManager -- Renders templates to files.

=== Legal

Copyright (C) 2007-2008 Igal Koshevoy (igal@pragmaticraft.com)

AutomateIt is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see: http://www.gnu.org/licenses/
