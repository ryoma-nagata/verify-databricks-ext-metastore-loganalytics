


## 前提条件

- Azure サブスクリプションに対する所有者権限
- docker
  - VSCode Remote Container環境
  - - [WSL 開発環境を設定するためのベスト プラクティス](https://docs.microsoft.com/ja-jp/windows/wsl/setup/environment) を参照して環境をセットアップしてください。「Docker を使用してリモート開発コンテナーを設定する」まで実行すればOKです。

## 手順

### 1. 本リポジトリをgit cloneか、ZIPダウンロードし、フォルダをVSCodeで開きます。

### 2. 変数情報の設定

「.devcontainer」フォルダ内の 「envtemplate」を「devcontainer.env」に名前変更して、内容を更新します。

### 3. Remote-Containerの起動

「Ctrl + Shigt + P」より、「Open Folder in Conteiner」を選択して、コンテナを起動します。

### 4. deply.shの実行

ターミナルを起動して、以下を実行します。

```BASH

bash deploy.sh

```

### 5. メタストア用のSQLを実行する

Azure SQL に接続し、以下のスクリプト内のsqlをすべて実行します。

./iac/code/databricks/externalMetastore/hive-schema-2.3.0.mssql.sql

## 確認内容

### 1. Hive Metastoreの同期

クラスタを作成する際にクラスターポリシーを設定します。

任意のワークスペースで、データベースかテーブルを作成し、他方のワークスペースで「Data」タブに反映されていることを確認します。

### 2. Log Analytics連携

Log Analyticsにアクセスし、spark関連のテーブルが作成されていることを確認します。