<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output omit-xml-declaration="yes" indent="yes" method="xhtml"/>

  <xsl:variable
      name="downloadPath"
      select="concat( 'http://download.eclipse.org', '@REPO_PATH@/' )" />

  <xsl:template match="/">
    <div id="midcolumn">

      <h1>@BUILD_TYPES@</h1>
      <p>@BUILD_TYPE_TAGLINE@</p>

      <h2>Software Site</h2>
      <p><small>The composite software site provides access to all available builds.</small></p>
      <p><img src="/gyrex/img/site.gif"/><code><a href="http://download.eclipse.org@REPO_PATH@/">http://download.eclipse.org@REPO_PATH@</a></code></p>

      <xsl:if test="/repository/children/child">
        <h3>Latest @BUILD_TYPE@</h3>
        <xsl:for-each select="/repository/children/child">
          <xsl:sort select="@location" order="descending"/>
          <xsl:if test="position() = 1">
            <xsl:call-template name="child"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:if>

      <xsl:if test="/repository/children/child">
        <h3>Past @BUILD_TYPES@</h3>
        <xsl:for-each select="/repository/children/child">
          <xsl:sort select="@location" order="descending"/>
          <xsl:if test="position() > 1">
            <xsl:call-template name="child"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:if>

    </div>

  </xsl:template>

  <!-- template for a child entry -->
  <xsl:template name="child">
    <p>
      <img src="/gyrex/img/site.gif"/>
      <code>
        <a>
          <xsl:attribute name="href">
            <xsl:value-of select="concat( $downloadPath, @location )"/>
          </xsl:attribute>
          <xsl:value-of select="@location"/>
        </a>
      </code>
    </p>
  </xsl:template>

</xsl:stylesheet>
