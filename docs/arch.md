Architecture
===

![](./images/arch.png)

このリポジトリはGitHub上で管理され、Cloud Buildが自動的にビルドします。ビルドされたアーティファクトはArtifact Registryへ登録され、GKEへデプロイされます。

## ビルド
Cloud Buildによって、このリポジトリの `main` ブランチが更新されると自動的に「プロジェクトのビルド」「コンテナイメージのビルド」「Artifact RegistryへのPush」が行われます。

またBackstageとは別にドキュメントのビルドもCloud Buildで同時にビルドしています。

## デプロイ
今のところGKEへのデプロイは手動で実行しています。これはこのBackstageインスタンスが頻繁に変更/デプロイされる予定はないからで、また個人の経験上GitOpsによる自動デプロイは個人プロジェクトにおいてToo Muchであると認識しているからです。👀

一方マニフェストは `/deploy` にまとめてあるため、GitOpsしようと思えばすぐできるようにしています。


## インフラストラクチャー
GKE AutopilotやSeaviceAccountの設定などは一通りTerraformで実装されています。


