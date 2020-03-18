# frozen_string_literal: true

require "rails_helper"

describe BitbucketURLParser do
  it "parses bitbucket urls" do
    [
      ["https://bitbucket.com/maxcdn/shml/", "maxcdn/shml"],
      ["https://foo.bitbucket.org/bar", "foo/bar"],
      ["git+https://bitbucket.com/hugojosefson/express-cluster-stability.git", "hugojosefson/express-cluster-stability"],
      ["sughodke.bitbucket.com/linky.js/", "sughodke/linky.js"],
      ["www.bitbucket.com/37point2/brainfuckifyjs", "37point2/brainfuckifyjs"],
      ["ssh://git@bitbucket.org:brozeph/node-craigslist.git", "brozeph/node-craigslist"],
      ["ssh+git@bitbucket.com:omardelarosa/tonka-npm.git", "omardelarosa/tonka-npm"],
      ["scm:svn:https://bitbucket.com/tanhaichao/top4j/tags/top4j-0.0.1", "tanhaichao/top4j"],
      ["scm:${project.scm.vendor}:git@bitbucket.com:adamcin/maven-s3-wagon.git", "adamcin/maven-s3-wagon"],
      ["scm:https://vert-x@bitbucket.com/purplefox/vert.x", "purplefox/vert.x"],
      ["scm:https:https://bitbucket.com/vaadin/vaadin.git", "vaadin/vaadin"],
      ["scm:https://bitbucket.com/daimajia/AndroidAnimations.git", "daimajia/AndroidAnimations"],
      ["scm:http:http://NICTA@bitbucket.com/NICTA/scoobi.git", "NICTA/scoobi"],
      ["scm:http:http://etorreborre@bitbucket.com/etorreborre/specs.git", "etorreborre/specs"],
      ["scm:hg:https://bitbucket.com/wangenyong/EnAndroidLibrary", "wangenyong/EnAndroidLibrary"],
      ["scm:hg:git://bitbucket.com/jesselong/muffero.git", "jesselong/muffero"],
      ["scm:git:ssh@bitbucket.com:claudius108/maven-plugins.git", "claudius108/maven-plugins"],
      ["scm:git|ssh://git@bitbucket.com/zinin/tomcat-redis-session.git", "zinin/tomcat-redis-session"],
      ["scm:git:prasadpnair@bitbucket.com/Jamcracker/jit-core.git", "Jamcracker/jit-core"],
      ["scm:git:scm:git:git://bitbucket.com/spring-projects/spring-integration.git", "spring-projects/spring-integration"],
      ["scm:git:https://bitbucket.com/axet/sqlite4java", "axet/sqlite4java"],
      ["scm:git:https://bitbucket.com/celum/db-tool.git", "celum/db-tool"],
      ["scm:git:https://ffromm@bitbucket.com/jenkinsci/slave-setup-plugin.git", "jenkinsci/slave-setup-plugin"],
      ["scm:git:bitbucket.com/yfcai/CREG.git", "yfcai/CREG"],
      ["scm:git@bitbucket.com:urunimi/PullToRefreshAndroid.git", "urunimi/PullToRefreshAndroid"],
      ["scm:git:bitbucket.com/larsrh/libisabelle.git", "larsrh/libisabelle"],
      ["scm:git://bitbucket.com/lihaoyi/ajax.git", "lihaoyi/ajax"],
      ["scm:git@bitbucket.com:ExpediaInc/ean-android.git", "ExpediaInc/ean-android"],
      ["https://RobinQu@bitbucket.com/RobinQu/node-gear.git", "RobinQu/node-gear"],
      ["https://taylorhakes@bitbucket.com/taylorhakes/promise-polyfill.git", "taylorhakes/promise-polyfill"],
      ["https://hcnode.bitbucket.com/node-gitignore", "hcnode/node-gitignore"],
      ["https://bitbucket.org/srcagency/js-slash-tail.git", "srcagency/js-slash-tail"],
      ["https://gf3@bitbucket.com/gf3/IRC-js.git", "gf3/IRC-js"],
      ["https://crcn:KQ3Lc6za@bitbucket.com/crcn/verify.js.git", "crcn/verify.js"],
      ["https://bgrins.bitbucket.com/spectrum", "bgrins/spectrum"],
      ["//bitbucket.com/dtrejo/report.git", "dtrejo/report"],
      ["=https://bitbucket.com/amansatija/Cus360MavenCentralDemoLib.git", "amansatija/Cus360MavenCentralDemoLib"],
      ["git+https://bebraw@bitbucket.com/bebraw/colorjoe.git", "bebraw/colorjoe"],
      ["git:///bitbucket.com/NovaGL/homebridge-openremote.git", "NovaGL/homebridge-openremote"],
      ["git://git@bitbucket.com/jballant/webpack-strip-block.git", "jballant/webpack-strip-block"],
      ["git://bitbucket.com/2betop/yogurt-preprocessor-extlang.git", "2betop/yogurt-preprocessor-extlang"],
      ["git:/git://bitbucket.com/antz29/node-twister.git", "antz29/node-twister"],
      ["git:/bitbucket.com/shibukawa/burrows-wheeler-transform.jsx.git", "shibukawa/burrows-wheeler-transform.jsx"],
      ["git:git://bitbucket.com/alaz/mongo-scala-driver.git", "alaz/mongo-scala-driver"],
      ["git:git@bitbucket.com:doug-martin/string-extended.git", "doug-martin/string-extended"],
      ["git:bitbucket.com//dominictarr/level-couch-sync.git", "dominictarr/level-couch-sync"],
      ["git:bitbucket.com/dominictarr/keep.git", "dominictarr/keep"],
      ["git:https://bitbucket.com/vaadin/cdi.git", "vaadin/cdi"],
      ["git@git@bitbucket.com:dead-horse/webT.git", "dead-horse/webT"],
      ["git@bitbucket.com:agilemd/then.git", "agilemd/then"],
      ["https : //bitbucket.com/alex101/texter.js.git", "alex101/texter.js"],
      ["git@git.bitbucket.com:daddye/stitchme.git", "daddye/stitchme"],
      ["bitbucket.com/1995hnagamin/hubot-achievements", "1995hnagamin/hubot-achievements"],
      ["git//bitbucket.com/divyavanmahajan/jsforce_downloader.git", "divyavanmahajan/jsforce_downloader"],
      ["scm:git:https://michaelkrog@bitbucket.com/michaelkrog/filter4j.git", "michaelkrog/filter4j"],
    ].each do |row|
      url, full_name = row
      url.unfreeze
      result = BitbucketURLParser.parse(url)
      expect(result).to eq(full_name)
    end
  end

  it "handles anchors" do
    full_name = "michaelkrog/filter4j"
    url       = "scm:git:https://michaelkrog@bitbucket.com/michaelkrog/filter4j.git#anchor"
    result    = BitbucketURLParser.parse(url)

    expect(result).to eq(full_name)
  end

  it "handles querystrings" do
    full_name = "michaelkrog/filter4j"
    url       = "scm:git:https://michaelkrog@bitbucket.com/michaelkrog/filter4j.git?foo=bar&wut=wah"
    result    = BitbucketURLParser.parse(url)

    expect(result).to eq(full_name)
  end

  it "handles brackets" do
    [
      ["[scm:git:https://michaelkrog@bitbucket.com/michaelkrog/filter4j.git]", "michaelkrog/filter4j"],
      ["<scm:git:https://michaelkrog@bitbucket.com/michaelkrog/filter4j.git>", "michaelkrog/filter4j"],
      ["(scm:git:https://michaelkrog@bitbucket.com/michaelkrog/filter4j.git)", "michaelkrog/filter4j"],
    ].each do |row|
      url, full_name = row
      result = BitbucketURLParser.parse(url)
      expect(result).to eq(full_name)
    end
  end

  it "doesnt parses non-bitbucket urls" do
    [
      "https://google.com",
      "https://bitbucket.com/foo",
      "https://bitbucker.com",
      "https://foo.bitbucket.io",
      "https://bitbucket.ibm.com/apiconnect/apiconnect",
    ].each do |url|
      result = BitbucketURLParser.parse(url)
      expect(result).to eq(nil)
    end
  end
end
