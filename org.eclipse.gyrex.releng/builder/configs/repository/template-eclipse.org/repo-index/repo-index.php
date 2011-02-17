<?php

# let's use most from Phoenix
# (note, we grab from www for latest content)
require_once('/home/data/httpd/download.eclipse.org/eclipse.org-common/system/app.class.php');
require_once('/home/data/httpd/download.eclipse.org/eclipse.org-common/system/nav.class.php');
require_once('/home/data/httpd/download.eclipse.org/eclipse.org-common/system/menu.class.php');

# initialize application
$App = new App();

# page settings
$pageTitle 		= "Gyrex - @BUILD_TYPES@";
$pageKeywords	= "gyrex, osgi, platform, server, equinox, dynamic, web, application";
$pageAuthor		= "Gyrex Committers";

# custom top-level menu
$Menu = new Menu();
$Menu->setMenuItemList(array());
$Menu->addMenuItem("Home", "/gyrex/", "_self");
$Menu->addMenuItem("Download", "/gyrex/download/", "_self");
$Menu->addMenuItem("Documentation", "/gyrex/documentation/", "_self");
$Menu->addMenuItem("Support", "/gyrex/support/", "_self");
$Menu->addMenuItem("Developers", "/gyrex/developers/", "_self");
$Menu->addMenuItem("About this Project", "/projects/project_summary.php?projectid=technology.gyrex", "_self");

# left nav menu
$Nav = new $Nav();
$Nav->setLinkList( array() );
$Nav->addCustomNav( "About This Project", "/projects/project_summary.php?projectid=technology.gyrex", "_self", 1 );
$Nav->addCustomNav("Gyrex", "/gyrex/", "_self", 1);
$Nav->addCustomNav("Blog", "http://gyrex.wordpress.com/", "_self", 1);
$Nav->addCustomNav("Wiki", "http://wiki.eclipse.org/Gyrex", "_self", 1);

# must prevent Eclipse.org promotion because we generate static output
$App->Promotion = FALSE;

# Google analytics code
$App->SetGoogleAnalyticsTrackingCode("UA-55532-14");
	
# add custom css styles and script
$App->AddExtraHtmlHeader( '<link rel="stylesheet" type="text/css" href="/gyrex/css/layout-fixes.css"/>' );
$App->AddExtraHtmlHeader( '<!--[if lt IE 8]><link rel="stylesheet" type="text/css" href="/gyrex/css/layout-fixes-ie.css"/><![endif]-->' );
$App->AddExtraHtmlHeader( '<script type="text/javascript" src="http://code.jquery.com/jquery-1.5.min.js"></script>' );

# set base to www.eclipse.org
$App->AddExtraHtmlHeader( '<base href="http://www.eclipse.org/"/>' );
	
# read composite content
$xmlDoc = new DOMDocument();
$xmlDoc->load( 'compositeContent.xml' );

# read stylesheet
$xslDoc = new DOMDocument();
$xslDoc->load( 'repo-index.xsl' );

# transform to HTML
$proc->importStylesheet( $xslDoc );
$html = $proc->transformToXML( $xmlDoc );

# patch html with left nav menu logo
$navHtmlPatch = <<<EOHTML
		
<div id="gyrex-small-header">
  <a href="http://www.eclipse.org/gyrex/"><div id="gyrex-small-logo"></div></a>
</div>

EOHTML;

# Generate the web page
$App->generatePage( "Nova", $Menu, $Nav, $author, $keywords, $title, $navHtmlPatch . $html );

