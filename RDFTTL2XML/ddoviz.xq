declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace ddo="http://www.dke.uni-linz.ac.at/ns/ddo#";
(: declare namespace ddo="http://dke.jku.at/ddo#"; :)
declare namespace n="http://dke.jku.at/ddo-hasNamedChild#";
declare namespace functx = "http://www.functx.com";

declare function functx:replace-first
  ( $arg as xs:string? ,
    $pattern as xs:string ,
    $replacement as xs:string )  as xs:string {

   replace($arg, concat('(^.*?)', $pattern),
             concat('$1',$replacement))
 } ;
 
declare function functx:index-of-match-first
  ( $arg as xs:string? ,
    $pattern as xs:string )  as xs:integer? {

  if (matches($arg,$pattern))
  then string-length(tokenize($arg, $pattern)[1]) + 1
  else ()
 } ;
declare function functx:get-matches-and-non-matches
  ( $string as xs:string? ,
    $regex as xs:string )  as element()* {

   let $iomf := functx:index-of-match-first($string, $regex)
   return
   if (empty($iomf))
   then <non-match>{$string}</non-match>
   else
   if ($iomf > 1)
   then (<non-match>{substring($string,1,$iomf - 1)}</non-match>,
         functx:get-matches-and-non-matches(
            substring($string,$iomf),$regex))
   else
   let $length :=
      string-length($string) -
      string-length(functx:replace-first($string, $regex,''))
   return (<match>{substring($string,1,$length)}</match>,
           if (string-length($string) > $length)
           then functx:get-matches-and-non-matches(
              substring($string,$length + 1),$regex)
           else ())
 } ;

(: 1. http://www.dke.uni-linz.ac.at/ddo/example/lbi/S/mrt/participant/jitai :)
(: 2. http://www.dke.uni-linz.ac.at/ddo/example/lbi/pastudy1/S/femaleparticipant/jitai :)
(: 3. http://www.dke.uni-linz.ac.at/ddo/example/lbi/pastudy1/jane/S/activityjitai :)

(: 1. http://example.org/jitais/ExampleStudy/CLASS/InterventionGroupParticipant/MotivationalMessage :)
declare function local:getActElem() as element() {
  let $doc := doc("running.rdf")
  (: let $doc := doc("newModel.xml") :)
  return $doc//rdf:Description[@rdf:about = "http://www.dke.uni-linz.ac.at/ddo/example/lbi/pastudy1/jane/S/jitai"]
};

declare function local:getContext($actElem as element()*) as xs:string {
  let $about := $actElem/@description
  let $trimmedAbout := fn:substring($about, 43, fn:string-length($about))
  let $duo := fn:tokenize($trimmedAbout, "/S")
  return fn:concat($duo[1], "/S")
  (: let $about := $actElem/@description
  return fn:concat($about, "/CLASS") :)
};

declare function local:getMetaClass($actElement as element()*) as element()* {
  let $doc := doc("running.rdf")//rdf:Description
  (: let $doc := doc("newModel.xml")//rdf:Description :)
  return
    if(not(exists($actElement/ddo:partOf))) then
      $actElement
    else
      local:getMetaClass($doc[@rdf:about = $actElement/ddo:partOf/@rdf:resource])
};

declare function local:getCurrentSequence() as element()* {
  let $actElem := local:getActElem()
  return
    if($actElem/@rdf:about = "http://www.dke.uni-linz.ac.at/ddo/example/lbi/S/mrt/participant/jitai") then
      doc("output.xml")//instance
    else if($actElem/@rdf:about = "http://www.dke.uni-linz.ac.at/ddo/example/lbi/pastudy1/S/femaleparticipant/jitai") then
      doc("output2.xml")//instance
    else
      doc("output3.xml")//instance
};

declare function local:getInstance($metaClass as element()*) as element()* {
  let $doc := doc("running.rdf")//rdf:Description
  (: let $doc := doc("newModel.xml")//rdf:Description :)
  let $instance := $doc[@rdf:about = $metaClass/ddo:metaOf/@rdf:resource]
  return $instance
};

declare function local:getInstanceHierarchy($instance as element()*) as element()* {
  let $doc := doc("running.rdf")//rdf:Description
  (: let $doc := doc("newModel.xml")//rdf:Description :)
  return
    if(exists($instance/ddo:partOf)) then
      ($instance, local:getInstanceHierarchy($doc[@rdf:about = $instance/ddo:partOf/@rdf:resource]))
    else
      $instance
};

declare function local:getInstanceData() as element()* {
  let $instance := local:getInstance(local:getMetaClass(local:getActElem()))
  let $instances := local:getInstanceHierarchy($instance)
  for $inst at $i in $instances
  return
    <instance description="{$inst/@rdf:about}" 
              label="{$inst/ddo:label}" 
              instanceLvl="{fn:count($instances) - $i}" 
              metaClass="{$inst/ddo:directInstanceOf/@rdf:resource}" 
              compParent="{$inst/ddo:partOf/@rdf:resource}">
    </instance>
};

declare function local:getContextElements($actElem) as element()* {
  let $doc := doc("running.rdf")
  (: let $doc := doc("newModel.xml") :)
  for $description in $doc//rdf:Description[not(fn:contains(@rdf:about, "/M")) and fn:contains(@rdf:about, local:getContext($actElem))]
  let $about := $description/@rdf:about
  order by $about
  return $description
};

declare function local:computeDepth($actElem as element()*, $level as xs:integer) as xs:integer {
  let $doc := doc("running.rdf")
  return 
    if(not(exists($actElem[ddo:partOf]))) then
      $level
    else
      local:computeDepth($doc//rdf:Description[@rdf:about = $actElem/ddo:partOf/@rdf:resource], $level + 1)
};

declare function local:computeParentLevelInContext($actElem as element()*, $level as xs:integer) as xs:integer {
  let $doc := doc("running.rdf")
  return 
    if(not(exists($actElem[ddo:directIntraContextSubClassOf]))) then
      $level
    else
      local:computeParentLevelInContext($doc//rdf:Description[@rdf:about = $actElem/ddo:directIntraContextSubClassOf/@rdf:resource], $level + 1)
};

declare function local:getContextHierarchy($ctxElements as element()*) as element()* {
  let $unordered :=
    for $elem in $ctxElements
    let $context := $elem/ddo:partOf
    let $name := $elem/@rdf:about
    let $ctx := $context/@rdf:resource
    for $el in $elem
    let $parent := $el/ddo:directIntraContextSubClassOf/@rdf:resource
    let $prefSuperclass :=
      if (not(exists($el/ddo:directIntraContextSubClassOf))) then
        $el/ddo:partOf/@rdf:resource
    return <class contextDepth="{local:computeDepth($elem, 0)}" parentLevel="{local:computeParentLevelInContext($el, 0)}" description="{$el/@rdf:about}" label="{$el/ddo:label}" ctx="{$ctx}" parent="{$parent[1]}" preferredSuperclass="{$prefSuperclass}">
           </class>
  for $class in $unordered
  let $contextDepth := $class/@contextDepth
  let $parentLevel := $class/@parentLevel
  let $desc := $class/@description
  order by $contextDepth, $parentLevel, $desc
  return $class
};

declare function local:getCtxElemsPerMetaClass() {
  let $sequence := local:getInstanceData()
  for $elem in $sequence
  let $ctxElements := local:getContextElements($elem)
  return
    <instance description="{$elem/@description}" label="{$elem/@label}" instanceLvl="{$elem/@instanceLvl}" metaClass="{$elem/@metaClass}" compParent="{$elem/@compParent}">
      {
        local:getContextHierarchy($ctxElements)
      }
    </instance>
};

declare function local:getParentClassesWithContextLevel($classes as element()*) as element()* {
  let $contexts := 
    for $class in $classes[@parent = ""]
    let $ctx := $class/@ctx
    group by $ctx
    return  <context ctx="{$ctx}">
              {
                $class
              }
            </context>
  for $context in $contexts
  for $class at $i in $context/class
    return <class contextDepth="{$class/@contextDepth}" contextLevel="{$i}" parentLevel="{$class/@parentLevel}" 
                  description="{$class/@description}" label="{$class/@label}" ctx="{$class/@ctx}" 
                  parent="{$class/@parent}" preferredSuperclass="{$class/@preferredSuperclass}">
           </class>
};

declare function local:calcCtxLvlRec($classes as element()*, $actElem as element()*, $ctxLvl as xs:double) as element()* {
  let $sequence := $classes
  let $children := $classes[@parent = $actElem/@description]
  return
    if(fn:empty($children)) then
      let $newElem :=
        <class contextDepth="{$actElem/@contextDepth}" contextLevel="{$ctxLvl}" parentLevel="{$actElem/@parentLevel}" 
               description="{$actElem/@description}" label="{$actElem/@label}" ctx="{$actElem/@ctx}" 
               parent="{$actElem/@parent}" preferredSuperclass="{$actElem/@preferredSuperclass}">
        </class>
      return $newElem
    else
      let $newElem :=
        <class contextDepth="{$actElem/@contextDepth}" contextLevel="{$ctxLvl}" parentLevel="{$actElem/@parentLevel}" 
               description="{$actElem/@description}" label="{$actElem/@label}" ctx="{$actElem/@ctx}" 
               parent="{$actElem/@parent}" preferredSuperclass="{$actElem/@preferredSuperclass}">
        </class>
      for $child at $i in $children
      return
      if ($i = 1) then
        ($newElem, local:calcCtxLvlRec($sequence, $child, $ctxLvl + ($i - 1)))
      else
        local:calcCtxLvlRec($sequence, $child, $ctxLvl + ($i - 1))
};

declare function local:getClassesWithContextLevel($classes as element()*) as element()* {
  let $unordered := 
    let $parentClasses := local:getParentClassesWithContextLevel($classes)
    for $parent in $parentClasses
      let $elements := local:calcCtxLvlRec($classes, $parent, $parent/@contextLevel/data())
    return $elements
  for $class in $unordered
  let $contextDepth := $class/@contextDepth
  let $parentLevel := $class/@parentLevel
  let $desc := $class/@description
  let $contextLevel := $class/@contextLevel
  let $parent := $class/@parent
  order by $contextDepth descending, $parentLevel, $desc
  return $class
};

declare function local:getCtxElemsWithCtxLvl() {
  let $sequence := local:getCtxElemsPerMetaClass()
  for $elem in $sequence
  return
    <instance description="{$elem/@description}" label="{$elem/@label}" instanceLvl="{$elem/@instanceLvl}" metaClass="{$elem/@metaClass}" compParent="{$elem/@compParent}">
      {
        local:getClassesWithContextLevel($elem//class)
      }
    </instance>
};

declare function local:getMaxContextDepth($sequence as element()*) as xs:double {
  let $max := max($sequence/@contextDepth)
  return $max
};

declare function local:getGroupedCtxLvls($actElem as element()*, $classes as element()*) as element()* { 
  let $sequence := $classes
  let $ctxElements := $sequence[@ctx = $actElem/@description]
  let $contextHeightPerLvl :=
    for $elem in $ctxElements
    let $ctxLvl := $elem/@contextLevel
    group by $ctxLvl
    return
      if(exists($sequence[@ctx = $elem/@description])) then
        let $subContextElements := $sequence[@ctx = $elem/@description]
        let $maxCtxLvl := max($subContextElements/@contextLevel)
        return 
        <ctxLvl actCtxLvl="{$ctxLvl}" maxCtxLvl="{$maxCtxLvl}">
          {
             local:getGroupedCtxLvls($elem, $sequence)
          }
        </ctxLvl>
      else
        <ctxLvl actCtxLvl="{$ctxLvl}" maxCtxLvl="0">
        </ctxLvl>
  return $contextHeightPerLvl
};

declare function local:calculateGroupedContextHeights($sequence, $height) as xs:double {
  if(fn:empty($sequence/ctxLvl)) then
    $height
  else
    local:calculateGroupedContextHeights($sequence/ctxLvl, $height + max($sequence/@maxCtxLvl))
};

declare function local:getGroupedParentLvls($actElem as element()*, $classes as element()*) as element()* {
  let $sequence := $classes
  let $ctxElements := $sequence[@ctx = $actElem/@description]
  let $contextWidthPerLvl :=
    for $elem in $ctxElements
    let $parenetLvl := $elem/@parentLevel
    group by $parenetLvl
    return
      if(exists($sequence[@ctx = $elem/@description])) then
        let $subContextElements := $sequence[@ctx = $elem/@description]
        let $maxParentLvl := max($subContextElements/@parentLevel)
        return 
        <parentLvl actParentLevel="{$parenetLvl}" maxParentLvl="{$maxParentLvl}">
          {
             local:getGroupedParentLvls($elem, $sequence)
          }
        </parentLvl>
      else
        <parentLvl actParentLevel="{$parenetLvl}" maxParentLvl="0">
        </parentLvl>
  return $contextWidthPerLvl
};

declare function local:getSequenceWithContextDimensions($classes as element()*) as element()* {
  let $unordered :=
    let $sequence := $classes
    for $class in $sequence
      return
        if(not(exists($sequence[@ctx = $class/@description]))) then
          <class contextHeight="0" contextWidth="0" contextDepth="{$class/@contextDepth}" contextLevel="{$class/@contextLevel}" 
                 parentLevel="{$class/@parentLevel}" description="{$class/@description}" label="{$class/@label}" 
                 ctx="{$class/@ctx}" parent="{$class/@parent}" preferredSuperclass="{$class/@preferredSuperclass}">
          </class>
        else
          let $contextElements := $classes[@ctx = $class/@description]
          let $maxCtxLvl := max($contextElements/@contextLevel)
          let $ctxLvls := local:getGroupedCtxLvls($class, $classes)
          let $contextHeight :=
            for $element in $ctxLvls
            return local:calculateGroupedContextHeights($element, 0)
            
          let $maxParentLvl := max($contextElements/@parentLevel)
          let $parentLvls := local:getGroupedParentLvls($class, $classes)
          let $contextWidth := sum($parentLvls//@maxParentLvl)
          return
          <class contextHeight="{sum($contextHeight) + $maxCtxLvl}" contextWidth="{$contextWidth + $maxParentLvl}" 
                 contextDepth="{$class/@contextDepth}" contextLevel="{$class/@contextLevel}" parentLevel="{$class/@parentLevel}" 
                 description="{$class/@description}" label="{$class/@label}" ctx="{$class/@ctx}" parent="{$class/@parent}" 
                 preferredSuperclass="{$class/@preferredSuperclass}">
          </class>     
              
  for $class in $unordered
  let $contextDepth := $class/@contextDepth
  let $parentLevel := $class/@parentLevel
  let $desc := $class/@description
  let $contextLevel := $class/@contextLevel
  order by $contextDepth, $parentLevel, $desc
  return $class
};


declare function local:getCtxElemsWithCtxDimensions() {
  let $sequence := local:getCtxElemsWithCtxLvl()
  for $elem in $sequence
  return
    <instance description="{$elem/@description}" label="{$elem/@label}" instanceLvl="{$elem/@instanceLvl}" metaClass="{$elem/@metaClass}" compParent="{$elem/@compParent}">
      {
        local:getSequenceWithContextDimensions($elem//class)
      }
    </instance>
};

declare function local:getCtxElemsWithInstanceLvl() {
  let $sequence := local:getCtxElemsWithCtxDimensions()
  for $elem in $sequence
  return 
    <instance description="{$elem/@description}" label="{$elem/@label}" instanceLvl="{$elem/@instanceLvl}" metaClass="{$elem/@metaClass}" compParent="{$elem/@compParent}">
      {
        for $class in $elem//class
        return
        <class instanceLevel="{$elem/@instanceLvl}" contextHeight="{$class/@contextHeight}" contextWidth="{$class/@contextWidth}" contextDepth="{$class/@contextDepth}" contextLevel="{$class/@contextLevel}" parentLevel="{$class/@parentLevel}" description="{$class/@description}" label="{$class/@label}" ctx="{$class/@ctx}" parent="{$class/@parent}" preferredSuperclass="{$class/@preferredSuperclass}">
        </class>
     }
    </instance>
};

declare function local:calculateOffsetMultiplier($actElement as element()*, $prevElement as element()*, $x as xs:double, $y as xs:double) as xs:double* {
  let $sequence := local:getCtxElemsWithInstanceLvl()//class
  let $offsets :=
    if ($actElement[@parent != ""]) then (
      let $parent := $sequence[@description = $actElement/@parent]
      return local:calculateOffsetMultiplier($parent, $actElement, $x + 1 + $parent/@contextWidth, $y)      
    ) else if ($actElement[@preferredSuperclass != ""]) then (
      let $preferredSuperclass := $sequence[@description = $actElement/@preferredSuperclass]
      let $ctxElements := $sequence[@ctx = $preferredSuperclass/@description]
      let $maxCtxHeightPerLvl := 
        let $actCtxLvl := 
          if(not(fn:empty($prevElement))) then
            $prevElement/@contextLevel
          else
            $actElement/@contextLevel
        for $ctxElement in $ctxElements[@contextLevel < $actCtxLvl]
        let $contextLvl := $ctxElement/@contextLevel
        group by $contextLvl
          return <lvl ctxLvl="{$contextLvl}" maxHeight="{max($ctxElement/@contextHeight)}">
                 </lvl>
      let $sumCtx := sum($maxCtxHeightPerLvl/@maxHeight)
      return 
        if (not(fn:empty($prevElement))) then
          local:calculateOffsetMultiplier($preferredSuperclass, $actElement, $x, $y + $prevElement/@contextLevel + $sumCtx)
        else
          local:calculateOffsetMultiplier($preferredSuperclass, $actElement, $x, $y + $actElement/@contextLevel + $sumCtx)
    ) else
      ($x, $y)
  return $offsets
};

declare function local:getInstanceOffset($actElement as element()*) as xs:double {
  let $sequence := local:getCtxElemsWithInstanceLvl()//class
  let $maxCtxHeightPerInstance :=
    let $actInstLvl := $actElement/@instanceLevel
    for $elem in $sequence[@instanceLevel < $actInstLvl]
    let $instanceLvl := $elem/@instanceLevel
    group by $instanceLvl
      return <lvl instLvl="{$instanceLvl}" maxHeight="{max($elem/@contextHeight)}">
             </lvl>
  let $sumInst := sum($maxCtxHeightPerInstance/@maxHeight)
  return $sumInst
};

declare function local:getElementStyling($actElement as element()*) as xs:string {
  let $actElemFromDoc := local:getActElem()
  let $sequence := local:getCtxElemsWithInstanceLvl()//class
  let $chosenElem := $sequence[@description = $actElemFromDoc/@rdf:about]
  let $strokeWidth := 
    if($actElement/@description = local:getActElem()/@rdf:about) then
      "10"
    else if(exists(local:getFatClasses()[@label = $actElement/@label])) then
      if($actElement/@instanceLevel < $chosenElem/@instanceLevel) then
        "7"
      else
        let $parentLvlCtxChosenElem := $sequence[@description = $chosenElem/@ctx]/@parentLevel
        let $parentLvlCtxActElem := $sequence[@description = $actElement/@ctx]/@parentLevel
        return
        if($parentLvlCtxActElem > $parentLvlCtxChosenElem) then
          "2"
        else
          "7"
    else
      "2"
  let $styleLvl := $actElement/@contextDepth + $actElement/@instanceLevel
  let $style := 
    if ($styleLvl = 0) then
      fn:concat("rounded=0;whiteSpace=wrap;html=1;fontSize=14;strokeWidth=", $strokeWidth, ";fontStyle=1;fillColor=#ffe6cc;strokeColor=#d79b00;")
    else if ($styleLvl = 1) then
      fn:concat("rounded=0;whiteSpace=wrap;html=1;fontSize=14;strokeWidth=", $strokeWidth, ";fontStyle=1;fillColor=#dae8fc;strokeColor=#6c8ebf;")
    else if ($styleLvl = 2) then
      fn:concat("rounded=0;whiteSpace=wrap;html=1;fontSize=14;strokeWidth=", $strokeWidth, ";fontStyle=1;fillColor=#d5e8d4;strokeColor=#82b366;")
    else if ($styleLvl = 3) then
      fn:concat("rounded=0;whiteSpace=wrap;html=1;fontSize=14;strokeWidth=", $strokeWidth, ";fontStyle=1;fillColor=#e1d5e7;strokeColor=#9673a6;")
    else if ($styleLvl = 4) then
      fn:concat("rounded=0;whiteSpace=wrap;html=1;fontSize=14;strokeWidth=", $strokeWidth, ";fontStyle=1;fillColor=#f8cecc;strokeColor=#b85450;")
    else
      fn:concat("rounded=0;whiteSpace=wrap;html=1;fontSize=14;strokeWidth=", $strokeWidth, ";fontStyle=1;")
  return $style
};

declare function local:getContextStyling($actElement as element()*) as xs:string {
  let $styleLvl := $actElement/@contextDepth + $actElement/@instanceLevel
  let $style := 
    if ($styleLvl = 0) then
      "rounded=1;whiteSpace=wrap;html=1;fontSize=14;strokeWidth=2;fillColor=#ffe6cc;strokeColor=#d79b00;"
    else if ($styleLvl = 1) then
      "rounded=1;whiteSpace=wrap;html=1;fontSize=14;strokeWidth=2;fillColor=#dae8fc;strokeColor=#6c8ebf;"
    else if ($styleLvl = 2) then
      "rounded=1;whiteSpace=wrap;html=1;fontSize=14;strokeWidth=2;fillColor=#d5e8d4;strokeColor=#82b366;"
    else if ($styleLvl = 3) then
      "rounded=1;whiteSpace=wrap;html=1;fontSize=14;strokeWidth=2;fillColor=#e1d5e7;strokeColor=#9673a6;"
    else if ($styleLvl = 4) then
      "rounded=1;whiteSpace=wrap;html=1;fontSize=14;strokeWidth=2;fillColor=#f8cecc;strokeColor=#b85450;"
    else
      "rounded=1;whiteSpace=wrap;html=1;fontSize=14;strokeWidth=2;"
  return $style
};

declare function local:getOnlyContextParents($sequence as element()*) as element()* {
  for $elem in $sequence
  let $elements :=
    if(exists($sequence[@ctx = $elem/@description])) then
      $elem
  return $elements
};

(: Zusätzliche Breite von Feldern auf einer Seite -> negativ :)

declare function local:calculateOffset($actElement as element()*) as xs:double {
  let $offset := -15 + $actElement/@contextWidth * -5
  return $offset
};

(: 
  heightOffset +
  (Abstand in der Höhe zwischen den Element * contextHeight) +
  (heightOffset + 
    heightOffset * (maximale contextDepth - (aktuelle contextDepth + 1)) -> liefert Wert zwischen 0...(maxContextDepth - 1), also 0 bis x-mal den heightOffset, abhängig
    von der Tiefe der Verschachtelung
  )
:)
declare function local:calculatePhysicalHeight($actElement as element()*, $sequence as element()*) as xs:double {
  let $height := 10 + (60 * ($actElement/@contextHeight)) + (10 + 10 * (local:getMaxContextDepth($sequence) - ($actElement/@contextDepth + 1)))
  return $height
};

(: 
  (-offset * 2, weil auf beiden Seiten) + 
  (Abstand in der Breite zwischen den Elementen * contextWidth) +
  (Breite der Elemente * (contextWidth + 1)) 
:)

declare function local:calculatePhysicalWidth($actElement as element()*) as xs:double {
  let $offset := local:calculateOffset($actElement)
  let $width := (-$offset * 2) + (80 * $actElement/@contextWidth) + (120 * ($actElement/@contextWidth + 1))
  return $width
};

declare function local:getModel() as element()*{
  let $xOffset := 200
  let $yOffset := 60
  let $sequence := local:getCtxElemsWithInstanceLvl()
  return
  <mxGraphModel>
    <root>
      <mxCell id="0"></mxCell>
      <mxCell id="1" parent="0"></mxCell>
      {
        let $yOffsetCtx := 30
        for $instance in $sequence
        let $contextElements := local:getOnlyContextParents($instance//class)
        for $elem in $contextElements
        let $coordinates := local:calculateOffsetMultiplier($elem, (), 0, 0)
        let $style := local:getContextStyling($elem)
        let $xOffsetCtx := local:calculateOffset($elem)
        let $instOffset := local:getInstanceOffset($elem)
        let $width := local:calculatePhysicalWidth($elem)
        let $height := local:calculatePhysicalHeight($elem, $instance//class)
        return
          <mxCell id="{fn:concat(data($elem/@description), "/field")}" value="" style="{$style}" parent="1" vertex="1">
            <mxGeometry x="{$coordinates[1] * $xOffset + $xOffsetCtx}" 
                        y="{($coordinates[2] + $instOffset + (2 * $elem/@instanceLevel)) * $yOffset + $yOffsetCtx}" 
                        width="{$width}" height="{$height}" as="geometry" />
          </mxCell>
      }
      {
        for $element in $sequence//class
        let $description := $element/@description
        let $coordinates := local:calculateOffsetMultiplier($element, (), 0, 0)
        let $style := local:getElementStyling($element)
        let $instOffset := local:getInstanceOffset($element)
        let $newStr :=
          for $element in functx:get-matches-and-non-matches($element/@label, "[A-Z][^A-Z]*")
            return $element/data()
        return
          <mxCell id="{data($element/@description)}" value="{$newStr}" style="{$style}" parent="1" vertex="1">
            <mxGeometry x="{$xOffset * $coordinates[1]}" 
                        y="{$yOffset * ($coordinates[2] + $instOffset + (2 * $element/@instanceLevel))}" 
                        width="120" height="40" as="geometry" />
          </mxCell>
      }
      {
        let $xOffset := -200
        for $element in $sequence
        let $description := $element/@description
        let $coordinates := local:calculateOffsetMultiplier($element, (), 0, 0)
        let $style := local:getElementStyling($element//class[@description = $element/@metaClass])
        let $instOffset := local:getInstanceOffset($element//class[@description = $element/@metaClass])
        let $newStr :=
          for $element in functx:get-matches-and-non-matches($element/@label, "[A-Z][^A-Z]*")
            return $element/data()
        return
          <mxCell id="{data($element/@description)}" value="{$newStr}" style="{$style}" parent="1" vertex="1">
            <mxGeometry x="{1.2 * $xOffset}" 
                        y="{$yOffset * ($coordinates[2] + $instOffset + (2 * $element/@instanceLvl))}" 
                        width="120" height="40" as="geometry" />
          </mxCell>
      }
      {
        let $sequence := local:getCtxElemsWithInstanceLvl()//class
        for $elem at $i in $sequence[@parent != ""]
        return
          <mxCell id="{concat(local:getContext(local:getActElem()), $i, "/arr")}" value="" 
                  style="endArrow=block;endSize=16;endFill=0;html=1;rounded=0;exitX=0;exitY=0.5;exitDx=0;exitDy=0;
                         fontSize=14;strokeWidth=2;fontStyle=1;entryX=1;entryY=0.5;entryDx=0;entryDy=0;edgeStyle=orthogonalEdgeStyle;" 
                        parent="1" source="{data($elem/@description)}" target="{data($elem/@parent)}" edge="1">
            <mxGeometry width="160" relative="1" as="geometry">
              <mxPoint as="sourcePoint" />
              <mxPoint as="targetPoint" />
            </mxGeometry>
          </mxCell>
      }
      {
        let $doc := doc("running.rdf")//rdf:Description
        let $metaClasses := local:getCtxElemsWithInstanceLvl()//@metaClass
        for $metaClass at $i in $metaClasses
        let $metaInClass := $doc[@rdf:about = $metaClass]
        let $parentOfMeta := $metaInClass/rdfs:subClassOf/@rdf:resource
        return
        if (not(fn:empty($parentOfMeta))) then
          <mxCell id="{concat(local:getContext(local:getActElem()), $i, "/metaArr")}" value="" 
                  style="endArrow=block;endSize=16;endFill=0;html=1;rounded=0;exitX=0.5;exitY=0;exitDx=0;exitDy=0;
                         fontSize=14;strokeWidth=2;fontStyle=1;entryX=0.5;entryY=1;entryDx=0;entryDy=0;edgeStyle=orthogonalEdgeStyle;" 
                         parent="1" source="{data($metaClass)}" target="{concat(data($parentOfMeta), "/field")}" edge="1">
            <mxGeometry width="160" relative="1" as="geometry">
              <mxPoint as="sourcePoint" />
              <mxPoint as="targetPoint" />
            </mxGeometry>
          </mxCell>
      }
      {
        for $instance at $i in $sequence
        return
          <mxCell id="{concat(local:getContext(local:getActElem()), $i, "/instArr")}" value="" 
                  style="endArrow=openThin;dashed=1;html=1;rounded=0;exitX=1;exitY=0.5;exitDx=0;exitDy=0;
                         fontSize=14;strokeWidth=2;fontStyle=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;" parent="1" 
                         source="{data($instance/@description)}" target="{data($instance/@metaClass)}" edge="1">
            <mxGeometry width="160" relative="1" as="geometry">
              <mxPoint as="sourcePoint" />
              <mxPoint as="targetPoint" />
            </mxGeometry>
          </mxCell>
      }
      {
        for $instance at $i in $sequence
        return
        if ($instance/@compParent != "") then
          <mxCell id="{concat(local:getContext(local:getActElem()), $i, "/compArr")}" value="" 
                  style="endArrow=diamondThin;endFill=1;endSize=24;html=1;rounded=0;exitX=0.5;exitY=0;exitDx=0;exitDy=0;
                         fontSize=14;strokeWidth=2;fontStyle=1;entryX=0.5;entryY=1;entryDx=0;entryDy=0;" parent="1" 
                         source="{data($instance/@description)}" target="{data($instance/@compParent)}" edge="1">
            <mxGeometry width="160" relative="1" as="geometry">
              <mxPoint as="sourcePoint" />
              <mxPoint as="targetPoint" />
            </mxGeometry>
          </mxCell>
      }
    </root>
  </mxGraphModel>
};

declare function local:getParentHierarchy($actElem as element()*, $sequence as element()*) as element()* {
  let $classes := $sequence
  return
  if(not(exists($sequence[@description = $actElem/@parent]))) then
    $actElem
  else
    ($actElem, local:getParentHierarchy($sequence[@description = $actElem/@parent], $classes))
};

declare function local:getFatClasses() as element()* {
  let $actElemFromDoc := local:getActElem()
  let $sequence := local:getCtxElemsWithInstanceLvl()//class
  let $actElem := $sequence[@description = $actElemFromDoc/@rdf:about]
  let $parentHierarchy := local:getParentHierarchy($actElem, $sequence)
  return $parentHierarchy
};


local:getModel()
(: local:getFatClasses() :)

(: let $sequence := local:getCtxElemsWithInstanceLvl()//class
let $actElem := $sequence[@description = "http://www.dke.uni-linz.ac.at/ddo/example/lbi/pastudy1/jane/S/jitai/proximaloutcome"]
return local:calculateOffsetMultiplier($actElem, (), 0, 0) :)










