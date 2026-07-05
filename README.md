<div align="center">
<img alt="logo" height="72" width="72" src="res/icon.png" />
<h2> 签到平台 </h2>
<p> 一个签到平台 Flutter 项目，后端使用 Supabase </p>
</div>

## 这是什么

这是一个基于Flutter打造的签到平台，支持账号登录，普通用户账号可以拍照签到，管理员账号可以发布任务、查看签到情况

<div align="center">
  <h3>用户界面</h3>
  <img alt="用户界面" src="res/user.jpg" />

  <h3>管理员界面</h3>
  <img alt="管理员界面" src="res/admin.jpg" />
</div>

## 后端结构介绍

本项目使用 Supabase 作为后端。仓库中只保留数据库迁移文件和示例配置。

- API URL 示例：`https://xxxxx.supabase.co`
- Publishable key 示例：`sb_publishable_xxxxx`
- 本地迁移文件目录：`supabase/migrations`

主要表：

- `profiles`：用户资料和角色，`role` 为 `user` 或 `admin`
- `sign_tasks`：签到任务
- `sign_records`：用户签到记录
- `avatars` Storage bucket：用户头像，私有 bucket
- `sign-photos` Storage bucket：签到现场照片，私有 bucket

公开表已启用 RLS，并通过策略限制用户只能访问自己允许访问的数据。请在部署到自己的 Supabase 项目后，结合实际业务再次检查 RLS、Storage policy 和注册策略。

## 获取 Supabase 配置

1. 打开 [Supabase](https://supabase.com/) 并注册或登录账号。
2. 在 Dashboard 中点击 `New project` 创建一个项目。
3. 等项目创建完成后，进入项目的 `Project Settings`。
4. 打开 `API` 页面。
5. 复制 `Project URL`，它的格式类似：

   ```text
   https://xxxxx.supabase.co
   ```

6. 在同一个 `API` 页面复制 `Project API keys` 中的 `publishable` key，格式类似：

   ```text
   sb_publishable_xxxxx
   ```


## 运行

克隆本仓库并安装Flutter开发环境

安装依赖：

```bash
flutter pub get
```
然后将上一步获取到的Supabase URL和API Keys填入 [lib/config/supabase_config.dart](lib/config/supabase_config.dart) 

```dart
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://xxxxx.supabase.co',
);

const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_xxxxx',
);
```

你还需要将 `supabase/migrations` 目录中的迁移应用到你自己的 Supabase 项目。你可以使用 Supabase CLI 应用这些迁移，也可以在 Supabase 网页版 Dashboard 的 SQL Editor 中按顺序执行迁移 SQL。

### 使用 Supabase CLI 初始化数据库

安装[Node.js](https://nodejs.org/)，然后在项目根目录执行：

```bash
npx supabase login
npx supabase init
npx supabase link --project-ref xxxxx
npx supabase db push --dry-run
npx supabase db push
npx supabase migration list
```
xxxxx 是  `https://xxxxx.supabase.co` 中的 xxxxx

### 初始化管理员

先在应用里注册一个账号，然后到 Supabase SQL Editor 执行：

```sql
update public.profiles
set role = 'admin'
where email = 'your-email@example.com';
```

重新登录后，该账号会进入管理端，可发布、编辑任务并查看签到统计。
