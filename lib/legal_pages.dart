import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({super.key, required this.type});

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final content = switch (type) {
      LegalDocumentType.terms => _terms,
      LegalDocumentType.privacy => _privacy,
      LegalDocumentType.location => _location,
    };

    return Scaffold(
      appBar: AppBar(title: Text(content.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              content.title,
              style: const TextStyle(
                color: foodInk,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content.updatedAt,
              style: const TextStyle(color: foodMuted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            ...content.sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: const TextStyle(
                        color: foodInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      section.body,
                      style: const TextStyle(
                        color: foodInk,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum LegalDocumentType { terms, privacy, location }

class _LegalContent {
  const _LegalContent({
    required this.title,
    required this.updatedAt,
    required this.sections,
  });

  final String title;
  final String updatedAt;
  final List<_LegalSection> sections;
}

class _LegalSection {
  const _LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}

const _terms = _LegalContent(
  title: '利用規約',
  updatedAt: '最終更新日: 2026年6月11日',
  sections: [
    _LegalSection(
      title: 'サービスの内容',
      body: 'Food Shareは、ユーザーが飲食店に関する投稿、検索、フォロー、グループ、メッセージ機能を利用できるサービスです。',
    ),
    _LegalSection(
      title: '禁止事項',
      body: '他者への嫌がらせ、虚偽情報の投稿、権利侵害、法令に反する投稿、不正アクセス、サービス運営を妨げる行為を禁止します。',
    ),
    _LegalSection(
      title: '投稿内容',
      body:
          'ユーザーは、自分が投稿する写真、コメント、店舗名、位置情報などについて責任を持つものとします。不適切な投稿は削除または制限される場合があります。',
    ),
    _LegalSection(
      title: 'アカウント停止・削除',
      body: '規約違反、迷惑行為、通報内容などにより、運営は投稿削除、機能制限、アカウント停止または削除を行うことがあります。',
    ),
    _LegalSection(
      title: '免責',
      body: '店舗情報、投稿内容、営業時間、価格などの正確性は保証されません。利用者は自己判断でサービスを利用してください。',
    ),
  ],
);

const _privacy = _LegalContent(
  title: 'プライバシーポリシー',
  updatedAt: '最終更新日: 2026年6月11日',
  sections: [
    _LegalSection(
      title: '取得する情報',
      body:
          'メールアドレス、ユーザー名、生年月日、性別、プロフィール画像、投稿写真、コメント、店舗名、位置情報、フォロー、グループ、DMに関する情報を取得します。',
    ),
    _LegalSection(
      title: '利用目的',
      body: 'アカウント管理、投稿表示、検索、レコメンド、フォロー、DM、通報対応、不正利用防止、サービス改善のために利用します。',
    ),
    _LegalSection(
      title: '第三者提供',
      body: '法令に基づく場合、利用者の同意がある場合、不正利用対応に必要な場合を除き、個人情報を第三者に販売しません。',
    ),
    _LegalSection(
      title: '外部サービス',
      body: '住所表示のために、地図やジオコーディングに関する外部サービスを利用する場合があります。',
    ),
    _LegalSection(
      title: '削除・問い合わせ',
      body: 'ユーザーは退会機能によりアカウント削除を依頼できます。投稿や個人情報の削除依頼にも対応します。',
    ),
  ],
);

const _location = _LegalContent(
  title: '位置情報の取り扱い',
  updatedAt: '最終更新日: 2026年6月11日',
  sections: [
    _LegalSection(
      title: '利用する位置情報',
      body: '投稿時に選択した地図上の地点、緯度経度、住所表示を保存し、投稿や地図検索に利用します。',
    ),
    _LegalSection(
      title: '公開範囲',
      body: '投稿に紐づく場所情報は、他のユーザーが投稿一覧、プロフィール、地図上で確認できる場合があります。',
    ),
    _LegalSection(
      title: '注意事項',
      body: '自宅、勤務先、学校など個人を特定されやすい場所を投稿しないでください。必要に応じて投稿削除を行ってください。',
    ),
    _LegalSection(
      title: '外部API',
      body: '座標から住所を取得するため、外部のジオコーディングAPIへ座標を送信する場合があります。',
    ),
  ],
);
