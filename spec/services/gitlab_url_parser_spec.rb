# frozen_string_literal: true
require 'rails_helper'

describe GitlabURLParser do
  it 'parses gitlab urls' do
    [
      ['https://gitlab.com/maxcdn/shml/', 'maxcdn/shml'],
      ['git+https://gitlab.com/hugojosefson/express-cluster-stability.git', 'hugojosefson/express-cluster-stability'],
      ['www.gitlab.com/37point2/brainfuckifyjs', '37point2/brainfuckifyjs'],
      ['ssh+git@gitlab.com:omardelarosa/tonka-npm.git', 'omardelarosa/tonka-npm'],
      ['scm:svn:https://gitlab.com/tanhaichao/top4j/tags/top4j-0.0.1', 'tanhaichao/top4j'],
      ['scm:${project.scm.vendor}:git@gitlab.com:adamcin/maven-s3-wagon.git', 'adamcin/maven-s3-wagon'],
      ['scm:https://vert-x@gitlab.com/purplefox/vert.x', 'purplefox/vert.x'],
      ['scm:https:https://gitlab.com/vaadin/vaadin.git', 'vaadin/vaadin'],
      ['scm:https://gitlab.com/daimajia/AndroidAnimations.git', 'daimajia/AndroidAnimations'],
      ['scm:http:http://NICTA@gitlab.com/NICTA/scoobi.git', 'NICTA/scoobi'],
      ['scm:http:http://etorreborre@gitlab.com/etorreborre/specs.git', 'etorreborre/specs'],
      ['scm:hg:https://gitlab.com/wangenyong/EnAndroidLibrary', 'wangenyong/EnAndroidLibrary'],
      ['scm:hg:git://gitlab.com/jesselong/muffero.git', 'jesselong/muffero'],
      ['scm:git:ssh@gitlab.com:claudius108/maven-plugins.git', 'claudius108/maven-plugins'],
      ['scm:git|ssh://git@gitlab.com/zinin/tomcat-redis-session.git', 'zinin/tomcat-redis-session'],
      ['scm:git:prasadpnair@gitlab.com/Jamcracker/jit-core.git', 'Jamcracker/jit-core'],
      ['scm:git:scm:git:git://gitlab.com/spring-projects/spring-integration.git', 'spring-projects/spring-integration'],
      ['scm:git:https://gitlab.com/axet/sqlite4java', 'axet/sqlite4java'],
      ['scm:git:https://gitlab.com/celum/db-tool.git', 'celum/db-tool'],
      ['scm:git:https://ffromm@gitlab.com/jenkinsci/slave-setup-plugin.git', 'jenkinsci/slave-setup-plugin'],
      ['scm:git:gitlab.com/yfcai/CREG.git', 'yfcai/CREG'],
      ['scm:git@gitlab.com:urunimi/PullToRefreshAndroid.git', 'urunimi/PullToRefreshAndroid'],
      ['scm:git:gitlab.com/larsrh/libisabelle.git', 'larsrh/libisabelle'],
      ['scm:git://gitlab.com/lihaoyi/ajax.git', 'lihaoyi/ajax'],
      ['scm:git@gitlab.com:ExpediaInc/ean-android.git', 'ExpediaInc/ean-android'],
      ['https://RobinQu@gitlab.com/RobinQu/node-gear.git', 'RobinQu/node-gear'],
      ['https://taylorhakes@gitlab.com/taylorhakes/promise-polyfill.git', 'taylorhakes/promise-polyfill'],
      ['https://gf3@gitlab.com/gf3/IRC-js.git', 'gf3/IRC-js'],
      ['https://crcn:KQ3Lc6za@gitlab.com/crcn/verify.js.git', 'crcn/verify.js'],
      ['//gitlab.com/dtrejo/report.git', 'dtrejo/report'],
      ['=https://gitlab.com/amansatija/Cus360MavenCentralDemoLib.git', 'amansatija/Cus360MavenCentralDemoLib'],
      ['git+https://bebraw@gitlab.com/bebraw/colorjoe.git', 'bebraw/colorjoe'],
      ['git:///gitlab.com/NovaGL/homebridge-openremote.git', 'NovaGL/homebridge-openremote'],
      ['git://git@gitlab.com/jballant/webpack-strip-block.git', 'jballant/webpack-strip-block'],
      ['git://gitlab.com/2betop/yogurt-preprocessor-extlang.git', '2betop/yogurt-preprocessor-extlang'],
      ['git:/git://gitlab.com/antz29/node-twister.git', 'antz29/node-twister'],
      ['git:/gitlab.com/shibukawa/burrows-wheeler-transform.jsx.git', 'shibukawa/burrows-wheeler-transform.jsx'],
      ['git:git://gitlab.com/alaz/mongo-scala-driver.git', 'alaz/mongo-scala-driver'],
      ['git:git@gitlab.com:doug-martin/string-extended.git', 'doug-martin/string-extended'],
      ['git:gitlab.com//dominictarr/level-couch-sync.git', 'dominictarr/level-couch-sync'],
      ['git:gitlab.com/dominictarr/keep.git', 'dominictarr/keep'],
      ['git:https://gitlab.com/vaadin/cdi.git', 'vaadin/cdi'],
      ['git@git@gitlab.com:dead-horse/webT.git', 'dead-horse/webT'],
      ['git@gitlab.com:agilemd/then.git', 'agilemd/then'],
      ['https : //gitlab.com/alex101/texter.js.git', 'alex101/texter.js'],
      ['git@git.gitlab.com:daddye/stitchme.git', 'daddye/stitchme'],
      ['gitlab.com/1995hnagamin/hubot-achievements', '1995hnagamin/hubot-achievements'],
      ['git//gitlab.com/divyavanmahajan/jsforce_downloader.git', 'divyavanmahajan/jsforce_downloader'],
      ['scm:git:https://michaelkrog@gitlab.com/michaelkrog/filter4j.git', 'michaelkrog/filter4j'],
    ].each do |row|
      url, full_name = row
      result = GitlabURLParser.parse(url)
      expect(result).to eq(full_name)
    end
  end

  it "handles anchors" do
    full_name = 'michaelkrog/filter4j'
    url       = 'scm:git:https://michaelkrog@gitlab.com/michaelkrog/filter4j.git#anchor'
    result    = GitlabURLParser.parse(url)

    expect(result).to eq(full_name)
  end

  it "handles querystrings" do
    full_name = 'michaelkrog/filter4j'
    url       = 'scm:git:https://michaelkrog@gitlab.com/michaelkrog/filter4j.git?foo=bar&wut=wah'
    result    = GitlabURLParser.parse(url)

    expect(result).to eq(full_name)
  end

  it "handles brackets" do
    [
      ['[scm:git:https://michaelkrog@gitlab.com/michaelkrog/filter4j.git]', 'michaelkrog/filter4j'],
      ['<scm:git:https://michaelkrog@gitlab.com/michaelkrog/filter4j.git>', 'michaelkrog/filter4j'],
      ['(scm:git:https://michaelkrog@gitlab.com/michaelkrog/filter4j.git)', 'michaelkrog/filter4j'],
    ].each do |row|
      url, full_name = row
      result = GitlabURLParser.parse(url)
      expect(result).to eq(full_name)
    end
  end

  it 'doesnt parses non-gitlab urls' do
    [
      'https://google.com',
      'https://gitlab.com/foo',
      'https://gitlab.com',
      'https://foo.gitlab.io',
      'https://gitlab.ibm.com/apiconnect/apiconnect'
    ].each do |url|
      result = GitlabURLParser.parse(url)
      expect(result).to eq(nil)
    end
  end
end
