# Nav-Item (CT8/Serv00 修改版)

基于 [`eooce/nav-item`](https://github.com/eooce/nav-item) 修改的导航站，专门为 CT8 / Serv00 环境做了适配，并**增加了数据导入导出功能**。

## 修改内容
1. **新增 `/api/data/export` 接口**：可导出所有菜单、卡片、广告和友链数据为 JSON 备份文件。
2. **新增 `/api/data/import` 接口**：可上传导出的 JSON 备份文件恢复数据。
3. **前端增加数据管理页面**：在后台管理 (`/admin`) 左侧菜单增加了“数据管理”入口。
4. **编译好了前端静态文件**：`public` 目录中已经包含了编译好的最新 Vue 前端代码，无需再手动构建。

## CT8 / Serv00 部署与更新教程

### 如果你是首次部署

可以直接使用修改后的一键安装脚本（需要你自行修改安装脚本的下载地址指向本仓库发行的 release 包）。
或者手动部署：
1. 在面板添加网站（Node.js 环境，指定好 node 路径）。
2. 下载本仓库的代码。
3. 运行 `npm install`。
4. 使用 `devil www restart 你的域名` 启动。

### 如果你已经在运行原版，如何更新？

1. **登录你的 CT8 服务器**：通过 SSH 登录。
2. **进入网站目录**：
   ```bash
   cd ~/domains/你的域名/public_nodejs
   ```
3. **备份数据库（可选但推荐）**：
   ```bash
   cp database/nav.db ../nav.db.bak
   ```
4. **下载并覆盖新文件**：
   直接使用压缩包覆盖是最简单的。
   ```bash
   wget -qO update.tar.gz https://github.com/saodisengyyds/nav-item-ct8/releases/download/v1.0.0/nav_with_data_import_export.tar.gz
   tar -xzf update.tar.gz
   rm update.tar.gz
   ```
   *(注意：你需要先在 GitHub Releases 中发布这个压缩包，才能使用上面的链接)*
5. **重启服务**：
   ```bash
   devil www restart 你的域名
   ```
6. **清理浏览器缓存**，重新访问 `https://你的域名/admin` 即可看到**数据管理**菜单。

## 声明
本项目仅为添加导入导出功能和重新构建前端，其他业务逻辑保持原样，原作者：[eooce](https://github.com/eooce/nav-item)。
