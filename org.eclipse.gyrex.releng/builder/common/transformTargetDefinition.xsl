<?xml version="1.0" encoding="UTF-8" ?>
<!--

   Transforms a target definition file into a set of p2 mirror Ant tasks.
   (https://bugs.eclipse.org/bugs/show_bug.cgi?id=266311#c12)

      <xslt style="transformTargetDefinition.xsl"
            in="${targetPlatform}"
            out="mirror_base.xml">
          <param name="destination" expression="${repoBaseLocation}/mirrored"/>
      </xslt>

      <ant antfile="mirror_base.xml" target="mirrorBasePlatform" />


 -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  <xsl:output method="xml" indent="yes" />
  <xsl:decimal-format decimal-separator="." grouping-separator="," />

  <xsl:param name="verbose" select="'false'" />
  <xsl:param name="destination" select="'file:${repoBaseLocation}/combined'" />

  <xsl:template match="target">
    <project name="Mirror base platforms" default="mirrorBasePlatform">
      <target name="mirrorBasePlatform" description="Mirrors a base platform for building">
        <xsl:apply-templates />
      </target>
    </project>
  </xsl:template>

  <xsl:template match="location[@type='InstallableUnit']">
    <xsl:variable name="locationUrl" select="./repository/@location" />
    <xsl:if test="$locationUrl">
      <p2.mirror destination="{$destination}" verbose="true">
        <slicingOptions includeOptional="false" includeNonGreedy="false" followStrict="true" />
        <source>
          <repository location="{$locationUrl}" />
        </source>
        <xsl:apply-templates />
      </p2.mirror>
    </xsl:if>
  </xsl:template>

  <xsl:template match="unit">
    <iu id="{@id}" version="{@version}" />
    <xsl:if test="not(substring(@id,string-length(@id)+1-string-length('.source'))='.source') and not(substring(@id,string-length(@id)+1-string-length('.feature.group'))='.feature.group')">
    <iu id="{@id}.source" version="{@version}" />
    </xsl:if>
  </xsl:template>

  <!-- ignore anything else -->
  <xsl:template match="environment|targetJRE|launcherArgs|includeBundles" />

</xsl:stylesheet>