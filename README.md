これはなに？
============

PukiWiki を使ったお仕事を少しだけ楽にするツールです。完全に自動化はでき
ないけど、そこそこ定型の仕事をお手伝いします。

何ができるの？
==============

 1. PukiWiki の calendar2 形式で指定日（デフォルトは今日）のページを作成
 2. 指定日のページの source をそのまま取得（同梱の raw プラグインを利用）
 3. 指定日のページの source をなんとなく setext っぽく変換
 4. 変換した setext ファイルを所定の場所にコピー
 5. 指定日のページに関する情報をメールで送る

何があれば使えるの？
====================

 * Ruby
 * Rubygems
 * Bundler
 * Rake
 * Mechanize
 * ちょっとした YAML の知識

どうやって使うの？
==================

ruby と必要な gem をインストール
--------------------------------

    $ gem install bundler
    $ bundle install --path vendor

とりあえず動くかどうか確認
--------------------------

    $ bundle exec rake

rake clean  # cleanup each namespace's backup and debugging pages

と表示されればたぶん（クライアントサイドは）正常に動いています。

raw.inc.php をセット
--------------------

PukiWiki の plugin/ ディレクトリに、同梱の lib/raw.inc.php を置いてくだ
さい。このツールはこの raw プラグインに依存しています。

※ 注意 ※

この plugin は認証などの情報を一切無視します。非公開の情報を扱うサイト
では導入しないでください。

YAMLファイルを用意
------------------

recipes/ ディレクトリの中に YAML で設定ファイルを置いてください。例えば
practice.yaml です。とりあえず中身は空でよいです。そしてまた rake を呼
びます。すると以下のように怒られます。

    rake aborted!
    PukiAssist::PukiWiki::ConfigForPukiwikiNotExist

今度は practice.yaml の中身を以下のようにしてください。

    pukiwiki:
      uri_host: 'http://pukiwiki.example.com'
      uri_base: '/PATH/TO/PUKIWIKI/'
      paganame_prefix: 'Log/'

三度目の rake. 今度は以下のように表示されるはずです。

    rake clean                 # cleanup each namespace's backup and debugging ...
    rake practice:clean        # cleanup backup files and mechanize debugging p...
    rake practice:create_page  # create new page on
    rake practice:fetch        # fetch PukiWiki raw data to 20090517-raw.txt
    rake practice:setextize    # covert PukiWiki to setext on 20090517-setext.txt

ご覧のように作った YAML ファイルの分だけ namespace ができ、その中にいく
つか task が現れます。

どのような設定項目があるかは recipes/format.yaml を読んでください。

YAML ファイルは UTF-8 で書いてください。

捕捉
====

work/ ディレクトリ
------------------

PukiWiki から取得した raw データ、これを setext 化したファイルは work/
ディレクトリ以下に、recipe 内に置いた YAML ファイルの名前のディレクトリ
を掘って保存されます。

上の例で言うと work/practice/ 以下に保存されます。

page/ ディレクトリ
------------------

このディレクトリには Mechanize 関係の情報が保存されます。通常は使いませ
ん。

    pukiwiki:
      debug: true

と設定すると Mechanize の取得した HTML、それをパースした結果が保存され
ます。

コツ
====

uri_base
--------

uri_base は PukiWiki の編集画面の textarea を Mechanize で探すために使っ
ています。基本的には PukiWiki を設置したパスを記述します。いちばん上の
階層に設置している場合は省略してもよいかもしれません。（もしかしたら
SCRIPT_NAME が要るかもしれません。）

pagename_prefix と date
-----------------------

基本的にこのツールは動作した日付か date: で明示した日付をページ名やファ
イル名に付加します。これは定期的に PukiWiki に関する操作が必要になると
いう状況を想定した設計となっています。

例えば

    pukiwiki:
      date: 2009-05-23
      pagename_prefix: Log

の場合は Log2009-05-23 というページを、

    pukiwiki:
      date: 2009-05-23
      pagename_prefix: Log/

の場合は Log/2009-05-23 というページを扱います。

しかしまったく日付と関係のないページを扱うこともできます。その場合は

    pukiwiki:
      date: ''   # ( or null )
      pagename_prefix: 完全なページ名

と、明示的に date: を空文字か null（nil は文字列 "nil" になってしまう）
にしてあげると、日付の関係ないページを扱うことができます。この場合
setext 用の設定も

    setext:
      filename_suffix: 完全なファイル名

と、補完されない日付の分も含めて完全なファイル名を指定してください。

それぞれどういうページ名やファイル名を扱おうとしているかは rake -T で確
認できます。

erb の使えるところ
------------------

以下の部分で erb が使えます。

    mail:
      subject:
      body:
    copy:
      path:

使いどころ
==========

 * PukiWiki を使ってドキュメントを書いているが、訳あってメールを使って
   その情報を共有したい
   * -> setext 形式に変換できるので Wiki に書いた内容をほぼそのままメー
        ルで送ってもあまり違和感がありません。
 * PukiWiki 上に定期的に情報を集約したいので calendar2 形式のページをサ
   クッと作成してその URL をメールで配信したい

また bin/pukiwiki2setext.rb は単体でも使えるので、わざわざ YAML を書い
たり raw プラグインを使ったりしなくても setext 形式のデータを得ることは
できます。

動作確認と制限
==============

Ruby 1.8.7, 1.9.2 で行っています。

ただし日本語を含む subject や from などのエンコーディングを伴うメール送
信は Ruby 1.8.6 以上でないと正しく動きません。少なくとも Ruby 1.8.5 に
添付されている nkf はバグっています。

ライセンス
==========

Two-clause BSD
