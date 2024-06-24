Seagull Backstage
===

Seagull BackstageはRyuSAの個人プロジェクトを横断して見れるようにまとめたIDP(Internal Developer Platform)です。ま、このリポジトリはPublicだからIDPならぬPDPかな？？ｶﾞﾊﾊ

このBackstageはCloud Buildでビルドされ、GKE Autopilotクラスター上にデプロイされています。

## アーキテクチャ

![](./images/arch.png)

このリポジトリはGitHub上で管理され、Cloud Buildが自動的にビルドします。ビルドされたアーティファクトはArtifact Registryへ登録され、GKEへデプロイされます。

詳細は [Architecture](./arch.md)

## カタログ管理
Backstageは "Component" / "API" / "System" などのエンティティを `catalog-info.yaml` というファイルで管理します。Seagullのプロジェクトは複数のリポジトリにまたがっているので、すべてを個別に登録せずに `Location` を利用して一括登録しています。

デモ用に、以下のコンポーネントだけしっかり書いてあります。

- Seagull Backstage
- x-ctf

